local config = require("config")



rednet.open(config.MODEM_SIDE)

local inventories = {}

-- =========================================================
-- DEBUG PRINT
-- =========================================================

local function log(text)

    print(text)
end

-- =========================================================
-- SCAN INVENTORIES
-- =========================================================

local function scanInventories()

    inventories = {}

    log("Scanning peripherals...")

    for _, name in ipairs(peripheral.getNames()) do

        local pType =
            peripheral.getType(name)

        log(name .. " [" .. tostring(pType) .. "]")

        local wrapped =
            peripheral.wrap(name)

        if wrapped then

            local ok, list =
                pcall(function()

                    return wrapped.list()
                end)

            if ok and type(list) == "table" then

                log(" -> inventory detected")

                table.insert(inventories, {

                    name = name,

                    peripheral = wrapped
                })
            end
        end
    end

    log("Inventories: " .. #inventories)
end

-- =========================================================
-- CREATE SNAPSHOT
-- =========================================================

local function createSnapshot()

    local items = {}

    local totalItems = 0
    local totalCapacity = 0


    for _, inv in ipairs(inventories) do

        local ok, list =
            pcall(function()

                return inv.peripheral.list()
            end)

        if ok and list then

            for _, item in pairs(list) do

                if item then

                    items[item.name] =
                        (items[item.name] or 0)
                        + item.count

                    totalItems =
                        totalItems + item.count
                end
            end
        end

        local ok2, size =
            pcall(function()

                return inv.peripheral.size()
            end)

        if ok2 and size then

            totalCapacity =
                totalCapacity + (size * 64)
        end
    end

    local percent = 0

    if totalCapacity > 0 then

        percent =
            (totalItems / totalCapacity)
            * 100
    end

    return {

        type = "snapshot",

        node = config.NODE_ID,

        label = config.DISPLAY_NAME,

        timestamp =
            os.epoch("utc"),

        storage = {

            totalItems =
                totalItems,

            capacity =
                totalCapacity,

            percent =
                percent
        },

        items = items
    }
end

-- =========================================================
-- ANNOUNCE
-- =========================================================

local function announce()

    rednet.broadcast({

        type = "node_announce",

        node = config.NODE_ID,

        label = config.DISPLAY_NAME

    }, config.PROTOCOL)
end

-- =========================================================
-- NETWORK LOOP
-- =========================================================

local function networkLoop()

    while true do

        local senderId,
              message,
              protocol =
            rednet.receive(
                config.PROTOCOL
            )

        if type(message) == "table" then

            if message.type ==
               "get_snapshot"
            then

                rednet.send(

                    senderId,

                    createSnapshot(),

                    config.PROTOCOL
                )
            end
        end
    end
end

-- =========================================================
-- HEARTBEAT LOOP
-- =========================================================

local function heartbeatLoop()

    while true do

        announce()

        sleep(30)
    end
end

-- =========================================================
-- RESCAN LOOP
-- =========================================================

local function rescanLoop()

    while true do

        scanInventories()

        sleep(60)
    end
end

scanInventories()

parallel.waitForAny(

    networkLoop,

    heartbeatLoop,

    rescanLoop
)
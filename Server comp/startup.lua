local config = require("config")

rednet.open(config.MODEM_SIDE)

local nodes = {}

local snapshots = {}

-- =========================================================
-- REQUEST SNAPSHOTS
-- =========================================================

local function requestSnapshots()

    for id, node in pairs(nodes) do

        rednet.send(

            id,

            {
                type = "get_snapshot"
            },

            config.PROTOCOL
        )
    end
end

-- =========================================================
-- CLEAN OFFLINE NODES
-- =========================================================

local function cleanupNodes()

    while true do

        local now = os.clock()

        for id, node in pairs(nodes) do

            if now - node.lastSeen
               >
               config.NODE_TIMEOUT
            then

                snapshots[node.node] = nil

                nodes[id] = nil
            end
        end

        sleep(10)
    end
end

-- =========================================================
-- BUILD GLOBAL STORAGE
-- =========================================================

local function buildGlobalStorage()

    local global = {}

    for nodeName, snap
        in pairs(snapshots)
    do

        for item, count
            in pairs(snap.items)
        do

            global[item] =
                (global[item] or 0)
                + count
        end
    end

    return global
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

            -- NODE ANNOUNCE

            if message.type ==
               "node_announce"
            then

                nodes[senderId] = {

                    id = senderId,

                    node =
                        message.node,

                    label =
                        message.label,

                    lastSeen =
                        os.clock()
                }
            end

            -- SNAPSHOT

            if message.type ==
               "snapshot"
            then

                snapshots[
                    message.node
                ] = message

                if nodes[senderId] then

                    nodes[senderId]
                        .lastSeen =
                            os.clock()
                end
            end

            -- DISPLAY CLIENT REQUEST

            if message.type ==
               "request_global"
            then

                rednet.send(

                    senderId,

                    {

                        type = "global_storage",

                        snapshots =
                            snapshots,

                        global =
                            buildGlobalStorage()
                    },

                    config.PROTOCOL
                )
            end
        end
    end
end

-- =========================================================
-- POLLING LOOP
-- =========================================================

local function pollingLoop()

    while true do

        requestSnapshots()

        sleep(
            config.SNAPSHOT_INTERVAL
        )
    end
end

parallel.waitForAny(

    networkLoop,

    pollingLoop,

    cleanupNodes
)
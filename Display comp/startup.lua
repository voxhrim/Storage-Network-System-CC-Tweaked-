local PROTOCOL = "storage_net"

local monitor = peripheral.find("monitor")

if not monitor then
    error("No monitor found")
end

rednet.open("back")

term.redirect(monitor)
monitor.setTextScale(0.5)

-- =========================================================
-- STATE
-- =========================================================

local currentPage = 1

local inventoryScroll = 1
local itemsScroll = 1

local selectedNodeIndex = 1

local pages = {
    "dashboard",
    "nodes",
    "items",
    "inventory"
}

local buttons = {}

-- =========================================================
-- COLORS
-- =========================================================

local COLORS = {
    bg = colors.black,
    text = colors.white,
    title = colors.cyan,
    border = colors.gray,
    success = colors.lime,
    warning = colors.orange,
    danger = colors.red,
    accent = colors.lightBlue,
    button = colors.gray,
    buttonActive = colors.lightBlue
}

-- =========================================================
-- UTILS
-- =========================================================

local function clear()

    monitor.setBackgroundColor(COLORS.bg)
    monitor.clear()
    monitor.setCursorPos(1,1)
end

local function centerText(y, text, color)

    local w, h = monitor.getSize()

    local x =
        math.floor((w - #text) / 2)

    monitor.setCursorPos(x, y)

    monitor.setTextColor(
        color or COLORS.text
    )

    monitor.write(text)
end

local function formatNumber(num)

    if num >= 1000000000 then
        return string.format("%.1fB", num / 1000000000)

    elseif num >= 1000000 then
        return string.format("%.1fM", num / 1000000)

    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    end

    return tostring(num)
end

local function shortName(name)

    local n =
        name:match(":(.+)$")
        or
        name

    n = n:gsub("_", " ")

    return n
end

local function progressBar(percent, width)

    local filled =
        math.floor(
            (percent / 100)
            * width
        )

    return
        string.rep("#", filled)
        ..
        string.rep("-", width - filled)
end

local function getBarColor(percent)

    if percent >= 90 then
        return COLORS.danger

    elseif percent >= 70 then
        return COLORS.warning
    end

    return COLORS.success
end

local function getSortedNodes(data)

    local nodes = {}

    if not data
       or
       not data.snapshots
    then
        return nodes
    end

    for _, snap
        in pairs(data.snapshots)
    do
        table.insert(nodes, snap)
    end

    table.sort(nodes,
        function(a,b)
            return a.label < b.label
        end
    )

    return nodes
end

-- =========================================================
-- BORDER
-- =========================================================

local function drawBorder()

    local w, h =
        monitor.getSize()

    monitor.setTextColor(
        COLORS.border
    )

    for x = 1, w do

        monitor.setCursorPos(x,1)
        monitor.write("-")

        monitor.setCursorPos(x,h)
        monitor.write("-")
    end

    for y = 1, h do

        monitor.setCursorPos(1,y)
        monitor.write("|")

        monitor.setCursorPos(w,y)
        monitor.write("|")
    end
end

-- =========================================================
-- HEADER
-- =========================================================

local function drawHeader()

    centerText(
        2,
        "STORAGE NETWORK",
        COLORS.title
    )

    centerText(
        3,
        "[" ..
        string.upper(
            pages[currentPage]
        )
        ..
        "]",
        COLORS.accent
    )
end

-- =========================================================
-- SCROLLBAR
-- =========================================================

local function drawScrollbar(
    totalItems,
    scroll,
    visibleRows,
    x,
    startY,
    height
)

    if totalItems <= visibleRows then
        return
    end

    local thumbHeight =
        math.max(
            2,
            math.floor(
                (visibleRows / totalItems)
                * height
            )
        )

    local maxScroll =
        math.max(
            1,
            totalItems - visibleRows
        )

    local progress =
        (scroll - 1)
        / maxScroll

    local thumbY =
        startY
        +
        math.floor(
            progress
            *
            (height - thumbHeight)
        )

    -- background

    monitor.setTextColor(
        colors.gray
    )

    for y = startY,
            startY + height
    do

        monitor.setCursorPos(x,y)
        monitor.write("|")
    end

    -- thumb

    monitor.setTextColor(
        COLORS.accent
    )

    for y = thumbY,
            thumbY + thumbHeight
    do

        if y <= startY + height then

            monitor.setCursorPos(x,y)
            monitor.write("#")
        end
    end
end

-- =========================================================
-- BUTTON
-- =========================================================

local function drawButton(
    x,
    y,
    width,
    label,
    active
)

    buttons[#buttons + 1] = {

        x1 = x,
        y1 = y,

        x2 = x + width - 1,
        y2 = y
    }

    if active then

        monitor.setBackgroundColor(
            COLORS.buttonActive
        )

        monitor.setTextColor(
            colors.black
        )

    else

        monitor.setBackgroundColor(
            COLORS.button
        )

        monitor.setTextColor(
            colors.white
        )
    end

    monitor.setCursorPos(x,y)

    local text =
        " "
        ..
        label
        ..
        " "

    while #text < width do
        text = text .. " "
    end

    monitor.write(text)

    monitor.setBackgroundColor(
        COLORS.bg
    )
end

-- =========================================================
-- DASHBOARD
-- =========================================================

local function drawDashboard(data)

    local y = 6

    local totalItems = 0
    local totalCapacity = 0
    local activeNodes = 0

    for _, snap
        in pairs(data.snapshots)
    do

        totalItems =
            totalItems
            +
            snap.storage.totalItems

        totalCapacity =
            totalCapacity
            +
            snap.storage.capacity

        activeNodes =
            activeNodes + 1
    end

    local percent = 0

    if totalCapacity > 0 then

        percent =
            (totalItems / totalCapacity)
            * 100
    end

    monitor.setCursorPos(4,y)

    monitor.setTextColor(
        COLORS.text
    )

    monitor.write(
        "TOTAL ITEMS: "
        ..
        formatNumber(totalItems)
    )

    y = y + 2

    monitor.setCursorPos(4,y)

    monitor.write(
        "ACTIVE NODES: "
        ..
        activeNodes
    )

    y = y + 2

    monitor.setCursorPos(4,y)
    monitor.write("NETWORK LOAD")

    y = y + 1

    local w, h =
        monitor.getSize()

    local bar =
        progressBar(
            percent,
            w - 10
        )

    monitor.setCursorPos(4,y)

    monitor.setTextColor(
        getBarColor(percent)
    )

    monitor.write(bar)

    monitor.setCursorPos(
        w - 8,
        y
    )

    monitor.write(
        string.format(
            "%.1f%%",
            percent
        )
    )
end

-- =========================================================
-- NODES
-- =========================================================

local function drawNodes(data)

    local y = 6

    local w, h =
        monitor.getSize()

    for _, snap
        in pairs(data.snapshots)
    do

        monitor.setCursorPos(3,y)

        monitor.setTextColor(
            COLORS.text
        )

        monitor.write(
            snap.label
        )

        y = y + 1

        local bar =
            progressBar(
                snap.storage.percent,
                w - 15
            )

        monitor.setCursorPos(5,y)

        monitor.setTextColor(
            getBarColor(
                snap.storage.percent
            )
        )

        monitor.write(bar)

        monitor.setCursorPos(
            w - 7,
            y
        )

        monitor.write(
            math.floor(
                snap.storage.percent
            )
            ..
            "%"
        )

        y = y + 2
    end
end

-- =========================================================
-- ITEMS
-- =========================================================

local function drawItems(data)

    local sorted = {}

    for item, count
        in pairs(data.global)
    do

        table.insert(sorted, {

            name = item,
            count = count
        })
    end

    table.sort(sorted,
        function(a,b)
            return a.count > b.count
        end
    )

    local w, h =
        monitor.getSize()

    local startY = 6

    local rows =
        h - startY - 3

    -- arrows

    monitor.setTextColor(
        COLORS.border
    )

    monitor.setCursorPos(w - 2, startY)
    monitor.write("^")

    monitor.setCursorPos(w - 2, h - 3)
    monitor.write("v")

    local index =
        itemsScroll

    for y = startY,
            startY + rows
    do

        local item =
            sorted[index]

        if not item then
            break
        end

        local name =
            shortName(
                item.name
            )

        local countText =
            formatNumber(
                item.count
            )

        local maxName =
            w - #countText - 8

        if #name > maxName then

            name =
                name:sub(
                    1,
                    maxName - 2
                )
                ..
                ".."
        end

        monitor.setCursorPos(3,y)

        monitor.setTextColor(
            COLORS.text
        )

        monitor.write(name)

        monitor.setTextColor(
            COLORS.accent
        )

        monitor.setCursorPos(
            w - #countText - 4,
            y
        )

        monitor.write(countText)

        index =
            index + 1
    end

    drawScrollbar(

        #sorted,

        itemsScroll,

        rows,

        w - 2,

        startY + 1,

        rows - 2
    )
end

-- =========================================================
-- INVENTORY
-- =========================================================

local function drawInventory(data)

    local nodes =
        getSortedNodes(data)

    if #nodes == 0 then

        centerText(
            10,
            "NO NODES",
            COLORS.danger
        )

        return
    end

    if selectedNodeIndex > #nodes then
        selectedNodeIndex = 1
    end

    local node =
        nodes[selectedNodeIndex]

    local items = {}

    for item, count
        in pairs(node.items)
    do

        table.insert(items, {

            name = item,
            count = count
        })
    end

    table.sort(items,
        function(a,b)
            return a.count > b.count
        end
    )

    local w, h =
        monitor.getSize()

    -- title

    monitor.setTextColor(
        COLORS.title
    )

    centerText(
        6,
        node.label
    )

    -- arrows

    monitor.setTextColor(
        COLORS.border
    )

    monitor.setCursorPos(2,6)
    monitor.write("<")

    monitor.setCursorPos(w - 1,6)
    monitor.write(">")

    monitor.setCursorPos(w - 2,8)
    monitor.write("^")

    monitor.setCursorPos(w - 2,h - 3)
    monitor.write("v")

    local startY = 8

    local rows =
        h - startY - 3

    local index =
        inventoryScroll

    for y = startY,
            startY + rows
    do

        local item =
            items[index]

        if not item then
            break
        end

        local name =
            shortName(
                item.name
            )

        local countText =
            formatNumber(
                item.count
            )

        local maxName =
            w - #countText - 8

        if #name > maxName then

            name =
                name:sub(
                    1,
                    maxName - 2
                )
                ..
                ".."
        end

        monitor.setCursorPos(3,y)

        monitor.setTextColor(
            COLORS.text
        )

        monitor.write(name)

        monitor.setTextColor(
            COLORS.accent
        )

        monitor.setCursorPos(
            w - #countText - 4,
            y
        )

        monitor.write(countText)

        index =
            index + 1
    end

    drawScrollbar(

        #items,

        inventoryScroll,

        rows,

        w - 2,

        startY,

        rows - 2
    )
end

-- =========================================================
-- FOOTER
-- =========================================================

local function drawFooter()

    buttons = {}

    local w, h =
        monitor.getSize()

    local labels = {
        "DASH",
        "NODES",
        "ITEMS",
        "INV"
    }

    local buttonWidth =
        math.floor(
            w / #labels
        )

    local x = 1

    for i, label
        in ipairs(labels)
    do

        drawButton(

            x,

            h - 1,

            buttonWidth,

            label,

            currentPage == i
        )

        x =
            x + buttonWidth
    end
end

-- =========================================================
-- TOUCH
-- =========================================================

local function handleTouch(x, y, data)

    local w, h =
        monitor.getSize()

    -- footer buttons

    for i, button
        in ipairs(buttons)
    do

        if x >= button.x1
           and
           x <= button.x2
           and
           y >= button.y1
           and
           y <= button.y2
        then

            currentPage = i

            inventoryScroll = 1
            itemsScroll = 1

            return
        end
    end

    -- ITEMS

    if pages[currentPage]
       ==
       "items"
    then

        if y < h / 2 then

            itemsScroll =
                math.max(
                    1,
                    itemsScroll - 3
                )

        else

            itemsScroll =
                itemsScroll + 3
        end

        return
    end

    -- INVENTORY

    if pages[currentPage]
       ==
       "inventory"
    then

        local nodes =
            getSortedNodes(data)

        -- previous node

        if x <= 4 then

            selectedNodeIndex =
                math.max(
                    1,
                    selectedNodeIndex - 1
                )

            inventoryScroll = 1

            return
        end

        -- next node

        if x >= w - 3 then

            selectedNodeIndex =
                math.min(
                    #nodes,
                    selectedNodeIndex + 1
                )

            inventoryScroll = 1

            return
        end

        -- scroll

        if y < h / 2 then

            inventoryScroll =
                math.max(
                    1,
                    inventoryScroll - 3
                )

        else

            inventoryScroll =
                inventoryScroll + 3
        end

        return
    end
end

-- =========================================================
-- MAIN LOOP
-- =========================================================

while true do

    rednet.broadcast(
        {
            type = "request_global"
        },
        PROTOCOL
    )

    local id, data =
        rednet.receive(
            PROTOCOL,
            3
        )

    clear()

    drawBorder()

    drawHeader()

    if data and
       data.type ==
       "global_storage"
    then

        if pages[currentPage]
           ==
           "dashboard"
        then

            drawDashboard(data)

        elseif pages[currentPage]
               ==
               "nodes"
        then

            drawNodes(data)

        elseif pages[currentPage]
               ==
               "items"
        then

            drawItems(data)

        elseif pages[currentPage]
               ==
               "inventory"
        then

            drawInventory(data)
        end

    else

        centerText(
            10,
            "NO SERVER",
            COLORS.danger
        )
    end

    drawFooter()

    local timer =
        os.startTimer(5)

    while true do

        local event,
              side,
              x,
              y =
            os.pullEvent()

        if event ==
           "monitor_touch"
        then

            handleTouch(
                x,
                y,
                data
            )

            break
        end

        if event ==
           "timer"
           and
           side == timer
        then
            break
        end
    end
end
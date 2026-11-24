-- WyrmWoodWilds - world container grid layout.
-- The vanilla container body is a UniformGridPanel populated with a hard-coded
-- 8 columns in native code. MaxSlotCount only adds rows, which overflows the
-- panel. This re-assigns each slot's UniformGridSlot column/row so large
-- containers use a wide layout that fits on screen.
--
-- UObject access must happen on the game thread. Newer UE4SS exposes
-- LoopInGameThreadWithDelay; older builds use LoopAsync + ExecuteInGameThread.
local TAG = "[WWStorageUI] "

local function say(fmt, ...)
    local ok, msg = pcall(string.format, fmt, ...)
    local text = TAG .. (ok and msg or tostring(fmt)) .. "\n"
    pcall(function() print(text) end)
end

local function valid(obj)
    if obj == nil then return false end
    local ok, res = pcall(function() return obj:IsValid() end)
    return ok and res == true
end

-- Slot count -> columns. Rows follow automatically.
-- 150 = 15x10, 128 = 16x8, 192 = 16x12, 208 = 16x13.
local COLUMNS = {
    [128] = 16,
    [150] = 15,
    [192] = 16,
    [208] = 16,
}

local function columns_for(n)
    local exact = COLUMNS[n]
    if exact then return exact end
    if n > 96 then return 16 end
    return 8
end

local function count_slots(body)
    -- MaxSlotCount is authoritative; InventorySlots may only contain widgets
    -- for used slots.
    local api = body.InventoryAPI
    if valid(api) then
        local inv = api.InventoryComponent
        if valid(inv) then
            local ok, n = pcall(function() return inv.MaxSlotCount end)
            if ok and type(n) == "number" and n > 0 then return n end
        end
    end
    local arr = body.InventorySlots
    if valid(arr) then
        local ok, n = pcall(function() return arr:GetArrayNum() end)
        if ok and type(n) == "number" and n > 0 then return n end
    end
    return 0
end

local function layout(body)
    if not valid(body) then return false end
    local grid = body.SlotGridContainer
    if not valid(grid) then return false, "no grid" end

    local n = count_slots(body)
    if n <= 0 then return false, "no slot count" end
    local cols = columns_for(n)

    local okChildren, children = pcall(function() return grid:GetChildren() end)
    if not okChildren or children == nil then return false, "no children" end
    local okNum, count = pcall(function() return children:GetArrayNum() end)
    if not okNum or type(count) ~= "number" or count == 0 then return false, "no child count" end

    for i = 1, count do
        local child = children[i]
        if valid(child) then
            local slot = child.Slot
            if valid(slot) then
                pcall(function() slot:SetColumn((i - 1) % cols) end)
                pcall(function() slot:SetRow(math.floor((i - 1) / cols)) end)
            end
        end
    end
    return true, count, cols
end

-- The vertical navigation SizeBox clamps the panel to 630 px. Widen it so a
-- 15-16 column grid has room without shrinking the slots.
local function widen_panel()
    local classes = {
        "WBP_WorldActorInventory_VerticalNavigation_C",
        "WBP_WorldActorInventory_VerticalNavigation",
    }
    for _, cls in ipairs(classes) do
        local ok, list = pcall(FindAllOf, cls)
        if ok and list then
            for _, v in ipairs(list) do
                if valid(v) then
                    local tree = v.WidgetTree
                    if valid(tree) then
                        local okw, box = pcall(function() return tree:FindWidget(FName("SizeBox_0")) end)
                        if not okw or not valid(box) then
                            okw, box = pcall(function() return tree:FindWidget("SizeBox_0") end)
                        end
                        if okw and valid(box) then
                            pcall(function() box:SetWidthOverride(1250.0) end)
                            pcall(function() box:SetMinDesiredWidth(1250.0) end)
                        end
                    end
                end
            end
        end
    end
end

local function find_bodies()
    local seen, result = {}, {}
    local classes = {
        "WBP_WorldActorInventory_InventoryBody_C",
        "WBP_WorldActorInventory_InventoryBody",
        "/Game/UI/WorldActorInventory/WBP_WorldActorInventory_InventoryBody.WBP_WorldActorInventory_InventoryBody_C",
    }
    for _, cls in ipairs(classes) do
        local ok, list = pcall(FindAllOf, cls)
        if ok and list then
            for _, obj in ipairs(list) do
                if valid(obj) then
                    local addr = tostring(obj:GetAddress())
                    if not seen[addr] then
                        seen[addr] = true
                        result[#result + 1] = obj
                    end
                end
            end
        end
    end
    return result
end

local reported = {}
local ticks = 0

local function tick()
    widen_panel()
    local bodies = find_bodies()
    ticks = ticks + 1
    if ticks <= 3 or (ticks <= 120 and ticks % 20 == 0) then
        say("tick %d bodies=%d", ticks, #bodies)
    end
    for _, body in ipairs(bodies) do
        local done, count, cols = layout(body)
        if done then
            local key = tostring(count) .. "x" .. tostring(cols)
            if reported[key] ~= true then
                reported[key] = true
                say("relaid %d slots as %d columns (%d rows)", count, cols, math.ceil(count / cols))
            end
        elseif ticks <= 3 then
            say("layout skipped: %s", tostring(cols))
        end
    end
end

if type(LoopInGameThreadWithDelay) == "function" then
    LoopInGameThreadWithDelay(500, function() pcall(tick) end)
    say("loaded (game-thread loop)")
else
    local busy = false
    LoopAsync(500, function()
        if not busy then
            busy = true
            ExecuteInGameThread(function()
                pcall(tick)
                busy = false
            end)
        end
        return false
    end)
    say("loaded (fallback loop)")
end

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
    [108] = 12,
    [130] = 13,
    [154] = 14,
    [180] = 15,
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

local described = {}

local function describe(body)
    local addr = tostring(body:GetAddress())
    if described[addr] then return end
    described[addr] = true
    local grid = body.SlotGridContainer
    local api = body.InventoryAPI
    local inv = valid(api) and api.InventoryComponent or nil
    local maxs, arrn, kid = "-", "-", "-"
    if valid(inv) then
        local ok, n = pcall(function() return inv.MaxSlotCount end)
        if ok then maxs = tostring(n) end
    end
    if valid(body.InventorySlots) then
        local ok, n = pcall(function() return body.InventorySlots:GetArrayNum() end)
        if ok then arrn = tostring(n) end
    end
    if valid(grid) then
        local ok, n = pcall(function() return grid:GetChildrenCount() end)
        if ok then kid = tostring(n) end
    end
    say("body grid=%s api=%s inv=%s max=%s arr=%s children=%s",
        tostring(valid(grid)), tostring(valid(api)), tostring(valid(inv)), maxs, arrn, kid)
end

local function layout(body)
    if not valid(body) then return false, "invalid body" end
    describe(body)
    local grid = body.SlotGridContainer
    if not valid(grid) then return false, "no grid" end

    local okCount, kidCount = pcall(function() return grid:GetChildrenCount() end)
    if not okCount or type(kidCount) ~= "number" then return false, "no child count" end
    if kidCount <= 0 then return false, "empty grid" end

    local n = count_slots(body)
    if n < kidCount then n = kidCount end
    local cols = columns_for(n)

    for i = 0, kidCount - 1 do
        local okChild, child = pcall(function() return grid:GetChildAt(i) end)
        if okChild and valid(child) then
            local slot = child.Slot
            if valid(slot) then
                pcall(function() slot:SetColumn(i % cols) end)
                pcall(function() slot:SetRow(math.floor(i / cols)) end)
            end
        end
    end
    return true, kidCount, cols
end

-- The world inventory panel is clamped by a SizeBox with WidthOverride=630 on
-- WBP_WorldActorInventory_VerticalNavigation. The property chain is not exposed
-- reliably from the body, so scan live SizeBox widgets and widen the world one.
local widened_count = 0

-- 1250 px starting at 700 runs past the right edge. Move the panel container
-- left and up so the whole grid is on screen.
local moved = false
local function move_panel_on_screen()
    local ok, main = pcall(FindFirstOf, "WBP_WorldActorInventory_MainPanel_C")
    if not ok or not valid(main) then return end
    local hb = nil
    pcall(function() hb = main.HorizontalBox_50 end)
    if not valid(hb) then
        pcall(function() hb = main:GetWidgetFromName(FName("HorizontalBox_50")) end)
    end
    if valid(hb) and valid(hb.Slot) then
        pcall(function() hb.Slot:SetPosition({ X = 620.0, Y = 80.0 }) end)
        if not moved then
            moved = true
            say("moved container panel to x=620")
        end
    end
end

local function widen_world_panels()
    -- Preferred: ask the live vertical navigation widget for its SizeBox.
    local okv, vlist = pcall(FindAllOf, "WBP_WorldActorInventory_VerticalNavigation_C")
    if not okv or vlist == nil then
        okv, vlist = pcall(FindAllOf, "WBP_WorldActorInventory_VerticalNavigation")
    end
    local byName = 0
    if okv and vlist then
        for _, v in ipairs(vlist) do
            if valid(v) then
                local okw, box = pcall(function() return v:GetWidgetFromName(FName("SizeBox_0")) end)
                if not okw or not valid(box) then
                    okw, box = pcall(function() return v:GetWidgetFromName("SizeBox_0") end)
                end
                if okw and valid(box) then
                    pcall(function() box:SetWidthOverride(1250.0) end)
                    pcall(function() box:SetMinDesiredWidth(1250.0) end)
                    pcall(function() box.WidthOverride = 1250.0 end)
                    pcall(function() box.bOverride_WidthOverride = true end)
                    byName = byName + 1
                end
            end
        end
    end
    if byName > 0 and widened_count ~= byName then
        widened_count = byName
        say("widened %d size box(es) by widget name", byName)
        move_panel_on_screen()
        return
    end

    local ok, list = pcall(FindAllOf, "SizeBox")
    if not ok or list == nil or #list == 0 then
        ok, list = pcall(FindAllOf, "/Script/UMG.SizeBox")
    end
    if not ok or list == nil then return end
    local changed = 0
    for _, sb in ipairs(list) do
        if valid(sb) then
            local okw, w = pcall(function() return sb.WidthOverride end)
            if okw and type(w) == "number" and w >= 600 and w <= 700 then
                local tree = sb:GetOuter()
                local owner = nil
                if valid(tree) then pcall(function() owner = tree:GetOuter() end) end
                local cls = ""
                if valid(owner) then
                    pcall(function() cls = owner:GetClass():GetFName():ToString() end)
                end
                if type(cls) == "string" and string.find(cls, "WorldActorInventory_VerticalNavigation") then
                    pcall(function() sb:SetWidthOverride(1250.0) end)
                    pcall(function() sb:SetMinDesiredWidth(1250.0) end)
                    pcall(function() sb.WidthOverride = 1250.0 end)
                    pcall(function() sb.bOverride_WidthOverride = true end)
                    changed = changed + 1
                end
            end
        end
    end
    if changed > 0 and widened_count ~= changed then
        widened_count = changed
        say("widened %d world panel size box(es)", changed)
        move_panel_on_screen()
    end
end

local function widen_panel(body)
    widen_world_panels()
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
    local bodies = find_bodies()
    ticks = ticks + 1
    if ticks <= 3 or (ticks <= 120 and ticks % 20 == 0) then
        say("tick %d bodies=%d", ticks, #bodies)
    end
    for _, body in ipairs(bodies) do
        widen_panel(body)
        local done, count, cols = layout(body)
        if done then
            local key = tostring(count) .. "x" .. tostring(cols)
            if reported[key] ~= true then
                reported[key] = true
                say("relaid %d slots as %d columns (%d rows)", count, cols, math.ceil(count / cols))
            end
        elseif ticks <= 3 then
            say("layout skipped: %s", tostring(count))
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

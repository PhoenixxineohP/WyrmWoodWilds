-- WyrmWoodWilds - wider farming spell areas.
-- Humidify: targeting box 150x150 (2 plots wide) -> 300x300 (4 plots wide);
--           capsule radius 150 -> 300; water cost 50 -> 200 (same water/plot).
-- Compost:  sphere radius 300 -> 450 (2.25x area); compost cost 150 -> 338.
local TAG = "[WWSpellAreas] "

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

local function load(path)
    local obj = nil
    pcall(function() obj = StaticFindObject(path) end)
    if not valid(obj) then
        pcall(function() obj = LoadAsset(path) end)
    end
    return obj
end

local function child_of(parent, className)
    local ok, list = pcall(FindAllOf, className)
    if not ok or list == nil then return nil end
    local parentAddr = tostring(parent:GetAddress())
    for _, obj in ipairs(list) do
        if valid(obj) then
            local outer = nil
            pcall(function() outer = obj:GetOuter() end)
            if valid(outer) and tostring(outer:GetAddress()) == parentAddr then
                return obj
            end
        end
    end
    return nil
end

local function apply()
    local humidify = load("/Game/Gameplay/UtilityMagic/PerkSpells/Farming/Humidify/USD_Humidify.USD_Humidify")
    if valid(humidify) then
        local box = child_of(humidify, "DominionShape_Box")
        if valid(box) then
            pcall(function() box.Extents = { X = 300.0, Y = 300.0, Z = 10.0 } end)
            say("Humidify box -> 300x300")
        else
            say("Humidify box not found")
        end
        local capsule = child_of(humidify, "DominionShape_Capsule")
        if valid(capsule) then
            pcall(function() capsule.Radius = 300.0 end)
        end
        local cost = child_of(humidify, "SpellModule_RemoveCombinedContentAmount")
        if valid(cost) then
            pcall(function() cost.AmountToRemove = 200 end)
            say("Humidify water cost -> 200")
        end
    else
        say("USD_Humidify not found")
    end

    local compost = load("/Agility/Gameplay/UtilityMagic/PerkSpells/Farming/USD_Farming_Compost.USD_Farming_Compost")
    if valid(compost) then
        local sphere = child_of(compost, "DominionShape_Sphere")
        if valid(sphere) then
            pcall(function() sphere.Radius = 450.0 end)
            say("Compost radius -> 450")
        else
            say("Compost sphere not found")
        end
        local cost = child_of(compost, "SpellModule_RemoveCombinedContentAmount")
        if valid(cost) then
            pcall(function() cost.AmountToRemove = 338 end)
            say("Compost cost -> 338")
        end
    else
        say("USD_Farming_Compost not found")
    end
end

pcall(apply)

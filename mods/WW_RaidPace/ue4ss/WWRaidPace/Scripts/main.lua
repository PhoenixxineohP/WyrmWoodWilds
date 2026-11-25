-- WyrmWoodWilds - raid pacing (default 25%) and manual pause.
-- Base raids are world-event definitions on BP_WorldEventManager. Their
-- AfterDuration triggers carry the cooldown and the periodic triggers carry a
-- chance. We scale both at run time; F7 toggles an effective pause while you
-- are staying at base.
local TAG = "[WWRaidPace] "
local SCALE = 4.0

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

local function duration_of(d)
    return {
        Days = tonumber(d.Days) or 0,
        Hours = tonumber(d.Hours) or 0,
        Minutes = tonumber(d.Minutes) or 0,
        Seconds = tonumber(d.Seconds) or 0,
    }
end

local function scale_duration(d, factor)
    local total = (((d.Days or 0) * 24 + (d.Hours or 0)) * 60 + (d.Minutes or 0)) * 60 + (d.Seconds or 0)
    total = math.floor(total * factor)
    local days = math.floor(total / 86400)
    total = total % 86400
    local hours = math.floor(total / 3600)
    total = total % 3600
    local minutes = math.floor(total / 60)
    local seconds = total % 60
    return { Days = days, Hours = hours, Minutes = minutes, Seconds = seconds }
end

local function each_manager(fn)
    local ok, managers = pcall(FindAllOf, "BP_WorldEventManager_C")
    if not ok or managers == nil then return end
    for _, mgr in ipairs(managers) do
        if valid(mgr) then fn(mgr) end
    end
end

local function each_trigger_in_manager(mgr, fn)
    local defs = nil
    pcall(function() defs = mgr.WorldEventDefinitions end)
    if defs == nil then return 0 end
    local okn, dn = pcall(function() return defs:GetArrayNum() end)
    if not okn or type(dn) ~= "number" then return 0 end
    local count = 0
    for i = 1, dn do
        local def = defs[i]
        if def ~= nil then
            local path = ""
            pcall(function() path = tostring(def.WorldEventClass.AssetPathName) end)
            if path == "" then pcall(function() path = tostring(def.WorldEventClass) end) end
            if type(path) == "string" and string.find(path, "BP_BaseRaidEvent") then
                local trigs = nil
                pcall(function() trigs = def.Triggers end)
                if trigs ~= nil then
                    local okt, tn = pcall(function() return trigs:GetArrayNum() end)
                    if okt and type(tn) == "number" then
                        for j = 1, tn do
                            local trig = trigs[j]
                            if valid(trig) then
                                local cls = ""
                                pcall(function() cls = trig:GetClass():GetFName():ToString() end)
                                if type(cls) == "string" then
                                    fn(trig, cls)
                                    count = count + 1
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return count
end

local applied = {}
local function apply()
    each_manager(function(mgr)
        local addr = tostring(mgr:GetAddress())
        if applied[addr] then return end
        applied[addr] = true
        local scaled = 0
        local total = each_trigger_in_manager(mgr, function(trig, cls)
            if string.find(cls, "AfterDuration") then
                local d = nil
                pcall(function() d = trig.Duration end)
                if d ~= nil then
                    pcall(function() trig.Duration = scale_duration(duration_of(d), SCALE) end)
                    scaled = scaled + 1
                end
            elseif string.find(cls, "PeriodicPercentage") then
                local c = nil
                pcall(function() c = trig.ChanceOfTriggering end)
                if type(c) == "number" then
                    pcall(function() trig.ChanceOfTriggering = c / SCALE end)
                    scaled = scaled + 1
                end
            end
        end)
        say("raid pacing x%.1f applied (%d/%d trigger(s))", SCALE, scaled, total)
    end)
end

-- F7: pause / resume raids for the current session.
local paused = false
local saved = {}
local function toggle_pause()
    paused = not paused
    each_manager(function(mgr)
        each_trigger_in_manager(mgr, function(trig, cls)
            local addr = tostring(trig:GetAddress())
            if string.find(cls, "AfterDuration") then
                if paused then
                    local d = nil
                    pcall(function() d = trig.Duration end)
                    if d ~= nil then
                        saved[addr] = { kind = "duration", value = duration_of(d) }
                        pcall(function() trig.Duration = { Days = 365, Hours = 0, Minutes = 0, Seconds = 0 } end)
                    end
                else
                    local previous = saved[addr]
                    if previous and previous.kind == "duration" then
                        pcall(function() trig.Duration = previous.value end)
                    end
                end
            elseif string.find(cls, "PeriodicPercentage") then
                if paused then
                    local c = nil
                    pcall(function() c = trig.ChanceOfTriggering end)
                    if type(c) == "number" then
                        saved[addr] = { kind = "chance", value = c }
                        pcall(function() trig.ChanceOfTriggering = 0.0 end)
                    end
                else
                    local previous = saved[addr]
                    if previous and previous.kind == "chance" then
                        pcall(function() trig.ChanceOfTriggering = previous.value end)
                    end
                end
            end
        end)
    end)
    say(paused and "raids paused (F7 to resume)" or "raids resumed")
end

pcall(function()
    RegisterKeyBind(Key.F7, {}, function()
        local ok = pcall(ExecuteInGameThread, toggle_pause)
        if not ok then pcall(toggle_pause) end
    end)
end)

if type(LoopInGameThreadWithDelay) == "function" then
    LoopInGameThreadWithDelay(3000, function() pcall(apply) end)
else
    local busy = false
    LoopAsync(3000, function()
        if not busy then
            busy = true
            ExecuteInGameThread(function() pcall(apply); busy = false end)
        end
        return false
    end)
end
say("loaded")

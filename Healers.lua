--[[local _, T = ...
T.EnemyHealers = {}
T.DamageTaken = {} 
T.MinHeal = 100 

local healerFrame = CreateFrame("Frame")
healerFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

healerFrame:SetScript("OnEvent", function(self, event, ...)
    local _, subEvent, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, spellSchool, amount = ...
    
    if not sourceFlags or not destName then return end


    if bit.band(sourceFlags, 0x00000400) ~= 0 and bit.band(sourceFlags, 0x00000040) ~= 0 then
        if subEvent == "SPELL_HEAL" or subEvent == "SPELL_PERIODIC_HEAL" then
            local healAmount = select(12, ...) 
            if type(healAmount) == "number" and healAmount >= (T.MinHeal or 100) then
                T.EnemyHealers[sourceName] = GetTime()
            end
        end
    end


    if bit.band(destFlags, 0x00000040) ~= 0 then
        if subEvent:find("_DAMAGE") then
            local dmg = select(subEvent:find("SWING") and 12 or 15, ...)
            if type(dmg) == "number" then
                T.DamageTaken[destName] = (T.DamageTaken[destName] or 0) + dmg
            end
        end
    end
end)

healerFrame:SetScript("OnUpdate", function(self, elapsed)
    self.t = (self.t or 0) + elapsed
    if self.t > 5 then
        local now = GetTime()
        for name, lastTime in pairs(T.EnemyHealers) do
            if (now - lastTime) > 60 then T.EnemyHealers[name] = nil end
        end
        local num = GetNumBattlefieldScores()
        for i = 1, num do
            local name, _, _, _, _, _, _, _, _, _, _, _, _, _, isDead = GetBattlefieldScore(i)
            if name and isDead and T.DamageTaken[name] then
                T.DamageTaken[name] = 0
            end
        end
        self.t = 0
    end
end)]]
local _, T = ...
local btn = CreateFrame("Button", "AT_SmartTarget", UIParent, "SecureActionButtonTemplate")
btn:SetAttribute("type", "macro")

local f = CreateFrame("Frame")
f:SetScript("OnUpdate", function(self, elapsed)
    if InCombatLockdown() then return end 
    
    if T.enemyFrames then
        for i = 1, 40 do
            local enemy = T.enemyFrames[i]
            if enemy and enemy:IsShown() and enemy.unitName and not enemy.isDeadAtList then
                btn:SetAttribute("macrotext", "/target " .. enemy.unitName)
                break
            end
        end
    end
end)
-- /click AT_SmartTarget

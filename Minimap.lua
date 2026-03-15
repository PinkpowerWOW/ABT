local _, T = ...
local MSG_PREFIX = "DBMv4-Tab"


if RegisterAddonMessagePrefix then RegisterAddonMessagePrefix(MSG_PREFIX) end

local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_ADDON")
f:SetScript("OnEvent", function(self, event, prefix, msg, channel, sender)
    if prefix ~= MSG_PREFIX then return end
    
    local sClean = sender:match("([^-]+)")
    if sClean == UnitName("player") then return end

    for unitData in msg:gmatch("([^|]+)") do
        local n, p, x, y = unitData:match("([^:]+):([^:]+):?([^:]*):?([^:]*)")
        
        if n and T.enemyFrames then
            local nClean = n:match("([^-]+)")
            for i = 1, 40 do
                local fr = T.enemyFrames[i]
                if fr and fr.unitName and fr.unitName:match("([^-]+)") == nClean then
                    fr.lastP = tonumber(p) / 100 
                    if x and x ~= "" then fr.unitX, fr.unitY = tonumber(x), tonumber(y) end
                    fr.syncTime = GetTime()
                    fr.hpText:SetTextColor(0, 0.8, 1) -- Сетевой цвет
                    break
                end
            end
        end
    end
end)

C_Timer.NewTicker(1.0, function() -- Можно 2 сек, так как AddonMsg не чат
    local _, type = IsInInstance()
    if type ~= "pvp" and type ~= "arena" then return end

    local hp, max = UnitHealth("player"), UnitHealthMax("player")
    if max <= 0 then return end
    
    local px, py = GetPlayerMapPosition("player")
    local myP = math.floor((hp/max)*100)
    local packet = string.format("%s:%d:%.3f:%.3f", UnitName("player"), myP, px or 0, py or 0)
    
    local count = 0
    for i = 1, 40 do
        if count >= 2 then break end
        local u = "nameplate"..i
        if UnitExists(u) and not UnitInRaid(u) and UnitHealth(u) < UnitHealthMax(u) then
            local p = math.floor((UnitHealth(u)/UnitHealthMax(u))*100)
            packet = packet .. "|" .. string.format("%s:%d", UnitName(u), p)
            count = count + 1
        end
    end

    pcall(SendAddonMessage, MSG_PREFIX, packet, "BATTLEGROUND")
end)

print("|cff00ff00AT-Sync:|r Работаем под капотом (AddonMsg).")

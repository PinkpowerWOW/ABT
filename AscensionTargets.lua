local _, T = ...
local CLASS_COLORS = RAID_CLASS_COLORS
local isTestMode = false
local SOLID_TEX = "Interface\\Buttons\\WHITE8X8"
local FLAG_ICON = "Interface\\WorldStateFrame\\HordeFlag" -- Иконка для вражеского флагоносца

local CLASS_MAP = {
    ["Воин"] = "WARRIOR", ["Маг"] = "MAGE", ["Разбойник"] = "ROGUE",
    ["Друид"] = "DRUID", ["Охотник"] = "HUNTER", ["Паладин"] = "PALADIN",
    ["Жрец"] = "PRIEST", ["Шаман"] = "SHAMAN", ["Чернокнижник"] = "WARLOCK",
    ["Рыцарь смерти"] = "DEATHKNIGHT", ["Mage"] = "MAGE", ["Warrior"] = "WARRIOR",
    ["Priest"] = "PRIEST", ["Warlock"] = "WARLOCK", ["Hunter"] = "HUNTER",
    ["Shaman"] = "SHAMAN", ["Rogue"] = "ROGUE", ["Druid"] = "DRUID",
    ["Paladin"] = "PALADIN", ["Death Knight"] = "DEATHKNIGHT"
}



-- 1. Основное окно
local mainFrame = CreateFrame("Frame", "AscensionTargetsParent", UIParent)
mainFrame:SetSize(230, 45)
mainFrame:SetPoint("CENTER")
mainFrame:SetMovable(true)
mainFrame:EnableMouse(true)
mainFrame:SetClampedToScreen(true)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", function(self) if not InCombatLockdown() then self:StartMoving() end end)
mainFrame:SetScript("OnDragStop", function(self) 
    self:StopMovingOrSizing() 
    local p, _, rp, x, y = self:GetPoint()
    if not AscensionTargetsDB then AscensionTargetsDB = {} end
    AscensionTargetsDB.point, AscensionTargetsDB.relPoint, AscensionTargetsDB.x, AscensionTargetsDB.y = p, rp, x, y
end)

local mainBG = mainFrame:CreateTexture(nil, "BACKGROUND")
mainBG:SetAllPoints(); mainBG:SetTexture(0, 0, 0, 0.6)

local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
title:SetPoint("TOP", 0, -8); title:SetText("ASCENSION TARGETS (BETA)")

-- 2. Создание фреймов
local enemyFrames = {}
local function CreateEnemyFrame(id)
    local f = CreateFrame("Button", "AscensionTarget_Enemy"..id, mainFrame, "SecureActionButtonTemplate")
    f:SetSize(210, 24)
    f:SetPoint("TOP", mainFrame, "TOP", 0, -(id-1)*28 - 35)
    f:SetAttribute("type1", "macro") 
    f:SetAttribute("type2", "macro") 

    f.hpBG = f:CreateTexture(nil, "BACKGROUND")
    f.hpBG:SetAllPoints(f); f.hpBG:SetTexture(SOLID_TEX); f.hpBG:SetVertexColor(0.02, 0.02, 0.02, 0.9)

    f.hpBar = f:CreateTexture(nil, "ARTWORK")
    f.hpBar:SetPoint("LEFT", f, "LEFT", 0, 0)
    f.hpBar:SetHeight(24); f.hpBar:SetTexture(SOLID_TEX)
    
    -- ИКОНКА ФЛАГА
    f.flag = f:CreateTexture(nil, "OVERLAY")
    f.flag:SetSize(20, 20)
    f.flag:SetPoint("RIGHT", f, "LEFT", -5, 0)
    f.flag:SetTexture(FLAG_ICON)
    f.flag:Hide()

    f.healerIcon = f:CreateTexture(nil, "OVERLAY")
    f.healerIcon:SetSize(18, 18)
    f.healerIcon:SetPoint("RIGHT", f, "LEFT", -25, 0) 
    f.healerIcon:SetTexture("Interface\\Icons\\Spell_Holy_Heal")
    f.healerIcon:Hide()

    f.border = CreateFrame("Frame", nil, f)
    f.border:SetPoint("TOPLEFT", f, -1, 1); f.border:SetPoint("BOTTOMRIGHT", f, 1, -1)
    f.border:SetBackdrop({ edgeFile = SOLID_TEX, edgeSize = 1 })
    f.border:SetBackdropBorderColor(0.8, 0, 0, 1)
    f.border:Hide()

    f.name = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.name:SetPoint("LEFT", 6, 0); f.name:SetShadowOffset(1, -1)
    
    f.hpText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.hpText:SetPoint("RIGHT", -6, 0)
    
    f:Hide(); return f
end
    for i = 1, 40 do 
        enemyFrames[i] = CreateEnemyFrame(i) 
    end
    T.enemyFrames = enemyFrames

local function HasFlag(name)
    for i = 1, GetNumWorldStateUI() do
        local _, state, _, text = GetWorldStateUIInfo(i)
        if state > 0 and text and text:find(name) then return true end
    end
    return false
end

local function UpdateList()
    local list = {}
    
    if isTestMode then
        local testClasses = {
            { "Воин", "WARRIOR" }, { "Паладин", "PALADIN" }, { "Охотник", "HUNTER" },
            { "Разбойник", "ROGUE" }, { "Жрец", "PRIEST" }, { "Рыцарь смерти", "DEATHKNIGHT" },
            { "Шаман", "SHAMAN" }, { "Маг", "MAGE" }, { "Чернокнижник", "WARLOCK" }
        }
        for i, data in ipairs(testClasses) do
            table.insert(list, { name = data[1], class = data[2], hp = 1.0, priority = i })
        end
    else
        local num = GetNumBattlefieldScores()
        for i = 1, num do
            local name, _, _, _, _, _, _, _, class = GetBattlefieldScore(i)
            if name and not UnitInRaid(name) and not UnitInParty(name) and name ~= UnitName("player") then
                local token = CLASS_MAP[class] or class or "UNKNOWN"
                table.insert(list, { name = name, class = token, priority = 0 })
            end
        end
    end

    for i = 1, 40 do
        local d, f = list[i], enemyFrames[i]
        if d then
            if not InCombatLockdown() then f:Show() end
            f.unitName = d.name
            f.name:SetText(d.name)
            local c = CLASS_COLORS[d.class] or {r=0.5, g=0.5, b=0.5}
            f.cR, f.cG, f.cB = c.r, c.g, c.b
            f.hpBar:SetVertexColor(c.r, c.g, c.b, 1) 
        else 
            if not InCombatLockdown() then f:Hide() end 
        end
    end
    if not InCombatLockdown() then mainFrame:SetHeight(#list * 28 + 50) end
end

-- 4. УЛЬТРА-ОБНОВЛЕНИЕ ХП 
local function UpdateData()
    if isTestMode then
        for i = 1, 9 do 
            local f = enemyFrames[i]
            if f and f:IsShown() then
                local speed = 0.3 + (i * 0.1)
                local p = 0.5 + 0.4 * math.sin(GetTime() * speed)
                
                f.hpBar:SetWidth(math.max(1, 210 * p))
                f.hpBar:SetVertexColor(f.cR or 0.5, f.cG or 0.5, f.cB or 0.5, 1)
                f.hpText:SetText(math.floor(p * 100) .. "%")
            end
        end
        return 
    end

    local curT = UnitName("target")
    
    for i = 1, 40 do
        local f = enemyFrames[i]
        if f and f:IsShown() and f.unitName then
            local uName = f.unitName
            local unitID = nil

            
            local r, g, b = f.cR or 0.5, f.cG or 0.5, f.cB or 0.5
            local mult = (curT and uName == curT) and 0.9 or 0.6

            if UnitName("target") == uName then 
                unitID = "target"
            elseif UnitName("focus") == uName then 
                unitID = "focus"
            elseif UnitName("mouseover") == uName then 
                unitID = "mouseover"
            else
                local numRaid = GetNumRaidMembers()
                if numRaid > 0 then
                    for j = 1, numRaid do
                        local rID = "raid"..j
                        if UnitName(rID.."target") == uName then
                            unitID = rID.."target"; break
                        elseif UnitName(rID.."targettarget") == uName then
                            unitID = rID.."targettarget"; break
                        end
                    end
                else
                    for j = 1, GetNumPartyMembers() do
                        local pID = "party"..j
                        if UnitName(pID.."target") == uName then
                            unitID = pID.."target"; break
                        elseif UnitName(pID.."targettarget") == uName then
                            unitID = pID.."targettarget"; break
                        end
                    end
                end

                if not unitID then
                    for j = 1, 40 do
                        if UnitName("nameplate"..j) == uName then
                            unitID = "nameplate"..j; break
                        end
                    end
                end
            end

            local p = f.lastP or 1.0

            if unitID then
                local h, m = UnitHealth(unitID), UnitHealthMax(unitID)
                p = (m > 0) and (h/m) or (UnitIsDeadOrGhost(unitID) and 0 or p)
                f.syncP = nil 
            elseif f.syncP then
                p = f.syncP
            else
                if T.DamageTaken and T.DamageTaken[uName] and T.DamageTaken[uName] > 0 then
                    local loss = T.DamageTaken[uName] / 30000 
                    p = math.max(0.01, p - loss)
                    T.DamageTaken[uName] = 0
                end
            end

            f.lastP = p

            f.hpBar:SetWidth(math.max(1, 210 * p))
            
            if p <= 0 or f.isDeadAtList then
                f.hpBar:SetVertexColor(0.2, 0.2, 0.2, 1)
                f.hpText:SetText("DEAD")
            else
                local alpha = unitID and 1 or 0.4
                f.hpBar:SetVertexColor(r * mult, g * mult, b * mult, alpha)
                f.hpText:SetText(math.floor(p*100).."%")
            end
            
            f.border:SetShown(curT and uName == curT)
        end
    end
end








-- 3. Логика списка
local function UpdateList()
    local list = {}
    
    if isTestMode then
        local testClasses = {
            { "Warrior", "WARRIOR" }, { "Paladin", "PALADIN" }, { "Hunter", "HUNTER" },
            { "Rogue", "ROGUE" }, { "Priest", "PRIEST" }, { "Death Knight", "DEATHKNIGHT" },
            { "Shaman", "SHAMAN" }, { "Mage", "MAGE" }, { "Warlock", "WARLOCK" }
        }
        for i = 1, #testClasses do
            local data = testClasses[i]
            table.insert(list, { 
                name = data[1],  
                class = data[2], 
                hp = 1.0, 
                priority = i, 
                isDead = false 
            })
        end
    else

        local num = GetNumBattlefieldScores()
        for i = 1, num do
            local name, _, _, _, _, _, _, _, class, _, _, _, _, _, isDead = GetBattlefieldScore(i)
            
            if name and not UnitInRaid(name) and not UnitInParty(name) and name ~= UnitName("player") then
                local token = CLASS_MAP[class] or class or "UNKNOWN"
                
                
                local currentHP = 1.0
                for j = 1, 40 do
                    if enemyFrames[j].unitName == name then
                        currentHP = enemyFrames[j].lastP or 1.0
                        break
                    end
                end

                
                local deadStatus = false
                if isDead == 1 or isDead == true or currentHP <= 0 then
                    deadStatus = true
                end

                local priority = deadStatus and 999 or currentHP
                
                table.insert(list, { 
                    name = name, 
                    class = token, 
                    priority = priority,
                    hp = currentHP,
                    isDead = deadStatus
                })
            end
        end
        table.sort(list, function(a, b) return a.priority < b.priority end)
    end

    for i = 1, 40 do
        local d, f = list[i], enemyFrames[i]
        if d then
            if not InCombatLockdown() then
                f:SetAttribute("macrotext1", "/target " .. d.name)
                f:SetAttribute("macrotext2", "/focus " .. d.name)
                f:Show() 
            end
            
            f.unitName = d.name
            f.name:SetText(d.name:gsub("%-.+", ""))
            
            local c = CLASS_COLORS[d.class] or {r=0.5, g=0.5, b=0.5}
            f.cR, f.cG, f.cB = c.r, c.g, c.b
            f.lastP = d.hp 
            f.isDeadAtList = d.isDead 
            
            f.flag:SetShown(HasFlag(d.name))
        else 
            if not InCombatLockdown() then 
                f:Hide() 
                f.unitName = nil 
            end 
        end
    end
    if not InCombatLockdown() then 
        mainFrame:SetHeight(#list * 28 + 50) 
    end
end

-- 5. События
mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
mainFrame:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
mainFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
mainFrame:RegisterEvent("BATTLEGROUND_POINTS_UPDATE")

mainFrame:SetScript("OnEvent", function(self, event, ...)
    local _, instanceType = IsInInstance()

    if event == "PLAYER_ENTERING_WORLD" then
        if AscensionTargetsDB and AscensionTargetsDB.point then
            self:ClearAllPoints(); self:SetPoint(AscensionTargetsDB.point, UIParent, AscensionTargetsDB.relPoint, AscensionTargetsDB.x, AscensionTargetsDB.y)
        end
        self:SetScale(AscensionTargetsDB and AscensionTargetsDB.scale or 1.0) 
        
        if instanceType == "pvp" then self:Show() else self:Hide() end

    elseif event == "BATTLEGROUND_POINTS_UPDATE" then
        local winner = GetBattlefieldWinner()
        if winner then self:Hide() end

    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent, _, _, _, _, _, destName = ...
        if subEvent == "UNIT_DIED" or subEvent == "UNIT_DESTROYED" then
            for i = 1, 40 do
                local f = enemyFrames[i]
                if f.unitName and f.unitName == destName then
                    f.lastP = 0
                    f.isDeadAtList = true
                    f.hpBar:SetWidth(1)
                    f.hpBar:SetVertexColor(0.2, 0.2, 0.2, 1)
                    f.hpText:SetText("DEAD") 
                    break
                end
            end
        end

    elseif event == "UPDATE_BATTLEFIELD_SCORE" then
        if not isTestMode then
            local num = GetNumBattlefieldScores()
            for i = 1, num do
                local name, _, _, _, _, _, _, _, _, _, _, _, _, _, isDead = GetBattlefieldScore(i)
                if name and (isDead == 0 or isDead == false) then
                    for j = 1, 40 do
                        local f = enemyFrames[j]
                        if f.unitName == name and f.isDeadAtList then
                            f.isDeadAtList = false
                            f.lastP = 1.0
                        end
                    end
                end
            end
            UpdateList()
        end
    end
end)


mainFrame:SetScript("OnUpdate", function(self, elapsed)
    self.t = (self.t or 0) + elapsed
    if self.t > 0.1 then UpdateData() end
    if self.t > 1.5 then 
        if not isTestMode then RequestBattlefieldScoreData() end
        UpdateList()
        self.t = 0 
    end
end)



SLASH_ATTEST1 = "/attest"
SlashCmdList["ATTEST"] = function()
    isTestMode = not isTestMode
    if isTestMode then
        mainFrame:Show()
        print("|cff00ff00AscensionTargets: Test Mode ON|r")
    else
        for i = 1, 40 do enemyFrames[i].unitName = nil end
        
        local _, instanceType = IsInInstance()
        if instanceType ~= "pvp" then mainFrame:Hide() end
        print("|cffff0000AscensionTargets: Test Mode OFF|r")
    end
    UpdateList()
end



-- 7. Кнопка у миникарты
local ldbIcon = CreateFrame("Button", "AscensionTargetsMinimapButton", Minimap)
ldbIcon:SetSize(32, 32)
ldbIcon:SetFrameStrata("MEDIUM")
ldbIcon:SetFrameLevel(10)
ldbIcon:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

-- Иконка
local iconTex = ldbIcon:CreateTexture(nil, "BACKGROUND")
iconTex:SetTexture("Interface\\Icons\\Spell_Holy_PrayerOfHealing")
iconTex:SetSize(20, 20)
iconTex:SetPoint("CENTER", 0, 0)

-- Ободок миникарты
local overlay = ldbIcon:CreateTexture(nil, "OVERLAY")
overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
overlay:SetSize(52, 52)
overlay:SetPoint("TOPLEFT", 0, 0)

-- Логика вращения
local function UpdateMapPos()
    local angle = AscensionTargetsDB and AscensionTargetsDB.minimapPos or 45
    local x = 80 * cos(angle)
    local y = 80 * sin(angle)
    ldbIcon:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

ldbIcon:SetMovable(true)
ldbIcon:RegisterForDrag("LeftButton")
ldbIcon:SetScript("OnDragStart", function(self) self:StartMoving() end)
ldbIcon:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local cx, cy = self:GetCenter()
    local mx, my = Minimap:GetCenter()
    local angle = math.deg(math.atan2(cy - my, cx - mx))
    if not AscensionTargetsDB then AscensionTargetsDB = {} end
    AscensionTargetsDB.minimapPos = angle
    UpdateMapPos()
end)

ldbIcon:SetScript("OnClick", function(self, button)
    isTestMode = not isTestMode
    if isTestMode then
        mainFrame:Show()
        print("|cff00ff00AscensionTargets: Тест включен|r")
    else
        local _, instanceType = IsInInstance()
        if instanceType ~= "pvp" then mainFrame:Hide() end
        print("|cffff0000AscensionTargets: Тест выключен|r")
    end
    UpdateList()
end)

-- Тултип
ldbIcon:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Ascension Targets")
    GameTooltip:AddLine("|cff00ff00LMB:|r Toggle Test Mode", 1, 1, 1)
    GameTooltip:AddLine("|cff00ff00Drag:|r Move Button", 1, 1, 1)
    GameTooltip:Show()
end)
ldbIcon:SetScript("OnLeave", function() GameTooltip:Hide() end)

UpdateMapPos()

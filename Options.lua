--[[local _, T = ...

if not AscensionTargetsDB then AscensionTargetsDB = {} end
if not AscensionTargetsDB.scale then AscensionTargetsDB.scale = 1.0 end
if not AscensionTargetsDB.minHeal then AscensionTargetsDB.minHeal = 100 end
if not AscensionTargetsDB.minimapPos then AscensionTargetsDB.minimapPos = 45 end

T.MinHeal = AscensionTargetsDB.minHeal

function CreateOptionsFrame()
    if AT_OptionsFrame then return AT_OptionsFrame end
    
    local f = CreateFrame("Frame", "AT_OptionsFrame", UIParent)
    f:SetSize(280, 160)
    f:SetPoint("CENTER")
    f:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(0, 0, 0, 0.9)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    tinsert(UISpecialFrames, "AT_OptionsFrame")

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -12)
    title:SetText("Ascension Targets")

    local s1 = CreateFrame("Slider", "AT_ScaleSlider", f, "OptionsSliderTemplate")
    s1:SetPoint("TOP", 0, -45)
    s1:SetMinMaxValues(0.5, 2.0)
    s1:SetValueStep(0.1)
    s1:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal") 
    s1:SetValue(AscensionTargetsDB.scale or 1.0)
    _G[s1:GetName()..'Text']:SetText("Масштаб: "..(AscensionTargetsDB.scale or 1.0))
    s1:SetScript("OnValueChanged", function(self, v)
        v = math.floor(v * 10) / 10
        _G[self:GetName()..'Text']:SetText("Масштаб: "..v)
        if AscensionTargetsParent then AscensionTargetsParent:SetScale(v) end
        AscensionTargetsDB.scale = v
    end)

    local s2 = CreateFrame("Slider", "AT_HealSlider", f, "OptionsSliderTemplate")
    s2:SetPoint("TOP", s1, "BOTTOM", 0, -30)
    s2:SetMinMaxValues(0, 5000)
    s2:SetValueStep(50)
    s2:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal") 
    s2:SetValue(AscensionTargetsDB.minHeal or 100)
    _G[s2:GetName()..'Text']:SetText("Порог хила: "..(AscensionTargetsDB.minHeal or 100))
    s2:SetScript("OnValueChanged", function(self, v)
        v = math.floor(v / 50) * 50
        _G[self:GetName()..'Text']:SetText("Порог хила: "..v)
        T.MinHeal = v
        AscensionTargetsDB.minHeal = v
    end)

    f:SetScript("OnShow", function()
        s1:SetValue(AscensionTargetsDB.scale or 1.0)
        s2:SetValue(AscensionTargetsDB.minHeal or 100)
    end)
    
    return f
end


SLASH_ATOPT1 = "/atopt"
SlashCmdList["ATOPT"] = function()
    local f = AT_OptionsFrame or CreateOptionsFrame()
    if f:IsShown() then f:Hide() else f:Show() end
end

local function InitMinimapButton()
    local btn = CreateFrame("Button", "AscensionTargetsMinimapBtn", Minimap)
    btn:SetSize(31, 31)
    btn:SetFrameLevel(20)
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetTexture("Interface\\Icons\\Spell_Holy_FlashHeal")

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetPoint("CENTER", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    local function UpdatePosition()
        local angle = AscensionTargetsDB.minimapPos or 45
        local x = math.cos(math.rad(angle)) * 80
        local y = math.sin(math.rad(angle)) * 80
        btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end

    btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local x, y = GetCursorPosition()
            local mx, my = Minimap:GetCenter()
            local scale = Minimap:GetEffectiveScale()
            local angle = math.deg(math.atan2(y/scale - my, x/scale - mx))
            AscensionTargetsDB.minimapPos = angle
            UpdatePosition()
        end)
    end)
    btn:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

    btn:SetScript("OnClick", function(self, button)
        if SlashCmdList["ATOPT"] then SlashCmdList["ATOPT"]() end
    end)

    UpdatePosition()
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    InitMinimapButton()
end)]]

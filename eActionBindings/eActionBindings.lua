local f = CreateFrame('Frame', 'eActionBindings', UIParent)

local _G = _G
local concat = table.concat
local insert = table.insert

local LibKeyBound = LibStub:GetLibrary('LibKeyBound-1.0')

BINDING_HEADER_EAB = 'eActionBindings'
BINDING_NAME_EAB_BUTTON1 = 'Button 1'
BINDING_NAME_EAB_BUTTON2 = 'Button 2'
BINDING_NAME_EAB_BUTTON3 = 'Button 3'
BINDING_NAME_EAB_BUTTON4 = 'Button 4'
BINDING_NAME_EAB_BUTTON5 = 'Button 5'
BINDING_NAME_EAB_BUTTON6 = 'Button 6'
BINDING_NAME_EAB_BUTTON7 = 'Button 7'
BINDING_NAME_EAB_BUTTON8 = 'Button 8'
BINDING_NAME_EAB_BUTTON9 = 'Button 9'
BINDING_NAME_EAB_BUTTON10 = 'Button 10'
BINDING_NAME_EAB_BUTTON11 = 'Button 11'
BINDING_NAME_EAB_BUTTON12 = 'Button 12'

f:EnableMouse(true)
f:SetFrameStrata('HIGH')
f:SetFrameLevel(100)
f:SetBackdrop({
    bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background',
    edgeFile = 'Interface\\DialogFrame\\UI-DialogBox-Border',
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
f:SetWidth(213)
f:SetHeight(200)
f:SetPoint('CENTER', UIParent, 'CENTER')
f:Hide()

local bindButton = CreateFrame('Button', 'eActionBindings_BindButton', f, 'UIPanelButtonTemplate')
bindButton:SetWidth(80)
bindButton:SetHeight(20)
eActionBindings_BindButtonText:SetText('Bind')
bindButton:SetPoint('BOTTOMLEFT', f, 'BOTTOMLEFT', 20, 20)
bindButton:SetScript('OnClick', function()
    LibKeyBound:Toggle()
end)

local closeButton = CreateFrame('Button', 'eActionBindings_CloseButton', f, 'UIPanelButtonTemplate')
closeButton:SetWidth(80)
closeButton:SetHeight(20)
eActionBindings_CloseButtonText:SetText('Close')
closeButton:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', -20, 20)
closeButton:SetScript('OnClick', function()
    PlaySound('gsTitleOptionOK')
    f:Hide()
end)

local function update_icon(self)
    local texture = GetActionTexture(self:GetID())
    local icon = _G[self:GetName() .. 'Icon']
    if texture then
        icon:Show()
        icon:SetTexture(texture)
    else
        icon:Hide()
    end
end

-- script handlers
local function click()
    if IsShiftKeyDown() then
        PickupAction(this:GetID())
    else
        PlaceAction(this:GetID())
    end

    update_icon(this)
    this:SetChecked(0)
end

local function enter()
    LibKeyBound:Set(this)

    GameTooltip_SetDefaultAnchor(GameTooltip, this)
    GameTooltip:SetAction(this:GetID())
end

local function leave()
    if GameTooltip:IsOwned(this) then
        GameTooltip:Hide()
    end
end

local function drag_start()
    PickupAction(this:GetID())
    update_icon(this)
end

local function receive_drag()
    PlaceAction(this:GetID())
    update_icon(this)
end
-- end script handlers

-- functions for LibKeyBound
local function GetHotkey(self)
    return LibKeyBound:ToShortKey(GetBindingKey(self:GetBindAction()))
end

local function GetBindAction(self)
    return 'EAB_BUTTON' .. (self:GetID() - 108)
end

local function SetKey(self, key)
    for _, hotkey in pairs({ GetBindingKey(self:GetBindAction()) }) do
        if key == hotkey then
            return
        end
    end

    SetBinding(key, self:GetBindAction())
end

local function GetBindings(self)
    local keys = {}
    for _, hotkey in pairs({ GetBindingKey(self:GetBindAction()) }) do
        insert(keys, GetBindingText(hotkey, 'KEY_'))
    end

    return concat(keys, ', ')
end

local function ClearBindings(self)
    for _, hotkey in pairs({ GetBindingKey(self:GetBindAction()) }) do
        SetBinding(hotkey, nil)
    end
end
-- end functions for LibKeyBound

-- initialize
local button
for i = 1, 12 do
    button = CreateFrame('CheckButton', 'eActionBindings_Button' .. i, f, 'ActionButtonTemplate')
    button:SetID(108 + i)

    -- position
    if i == 1 then
        button:SetPoint('TOPLEFT', f, 'TOPLEFT', 20, -20)
    elseif mod(i - 1, 4) == 0 then
        button:SetPoint('TOPLEFT', _G['eActionBindings_Button' .. (i - 4)], 'BOTTOMLEFT', 0, -10)
    else
        button:SetPoint('TOPLEFT', _G['eActionBindings_Button' .. (i - 1)], 'TOPRIGHT', 10, 0)
    end

    -- make the icon prettier
    _G['eActionBindings_Button' .. i .. 'Icon']:SetTexCoord(0.05, 0.95, 0.05, 0.95)

    -- functions required by LibKeyBound
    button.GetHotkey = GetHotkey
    button.SetKey = SetKey
    button.GetBindings = GetBindings
    button.GetBindAction = GetBindAction
    button.ClearBindings = ClearBindings

    button:RegisterForClicks('LeftButtonUp')
    button:RegisterForDrag('LeftButton')
    button:SetScript('OnClick', click)
    button:SetScript('OnEnter', enter)
    button:SetScript('OnLeave', leave)
    button:SetScript('OnDragStart', drag_start)
    button:SetScript('OnReceiveDrag', receive_drag)

    update_icon(button)
end

-- slash command for opening eActionBindings
SLASH_eActionBindings1 = "/eab"
function SlashCmdList.eActionBindings()
    -- update all icons first
    for i = 1, 12 do
        update_icon(_G['eActionBindings_Button' .. i])
    end

    f:Show()
end

-- make it closable via escape
insert(UISpecialFrames, 'eActionBindings')

local f = CreateFrame('Frame')
local macroItems
local macroItemButtons = {}
local dummy = function() return end

local _G = _G
local gsub = string.gsub
local match = string.match
local insert = table.insert
local concat = table.concat

local LibKeyBound = LibStub:GetLibrary('LibKeyBound-1.0')

-- buttons to add KeyBound support to
f.BindMapping = {
    ActionButton = 'ACTIONBUTTON',
    MultiBarBottomLeftButton = 'MULTIACTIONBAR1BUTTON',
    MultiBarBottomRightButton = 'MULTIACTIONBAR2BUTTON',
    MultiBarLeftButton = 'MULTIACTIONBAR4BUTTON',
    MultiBarRightButton = 'MULTIACTIONBAR3BUTTON',
    PetActionButton = 'BONUSACTIONBUTTON'
}

-- functions for LibKeyBound
function f:GetHotkey()
    return LibKeyBound:ToShortKey(GetBindingKey(self:GetBindAction()))
end

function f:GetBindAction()
    local name = self:GetName()
    local num = match(name, '%d+$')

    name = gsub(name, '%d+$', '')
    return f.BindMapping[name] .. num
end

function f:SetKey(key)
    for _, hotkey in pairs({ GetBindingKey(self:GetBindAction()) }) do
        if key == hotkey then
            return
        end
    end

    SetBinding(key, self:GetBindAction())
end

function f:GetBindings()
    local keys = {}
    for _, hotkey in pairs({ GetBindingKey(self:GetBindAction()) }) do
        insert(keys, GetBindingText(hotkey, 'KEY_'))
    end

    return concat(keys, ', ')
end

function f:ClearBindings()
    for _, hotkey in pairs({ GetBindingKey(self:GetBindAction()) }) do
        SetBinding(hotkey, nil)
    end
end
-- end functions for LibKeyBound

function f:PLAYER_LOGIN()
    -- add KeyBound stuff to buttons
    for buttonName, _ in pairs(f.BindMapping) do
        for i = 1, 12 do
            local button = _G[buttonName .. i]
            if button then
                -- add keybound and show hotkey and name on mouseover
                local OnEnter = button:GetScript('OnEnter')
                button:SetScript('OnEnter', function()
                    LibKeyBound:Set(this)

                    local hotkey = _G[this:GetName() .. 'HotKey']
                    local name = _G[this:GetName() .. 'Name']

                    if hotkey and hotkey:GetText() ~= RANGE_INDICATOR then
                        hotkey:Show()
                    end

                    if name and not this.macroItem then
                        name:Show()
                    end

                    if OnEnter then
                        OnEnter()
                    end

                    -- set item tooltip if this is a macro using UseItemByName
                    if this.macroItem and GameTooltip:IsOwned(this) then
                        local bag, slot = GetContainerItemByName(this.macroItem)
                        if bag and slot then
                            GameTooltip:SetBagItem(bag, slot)
                        end
                    end
                end)

                -- hide hotkey/name again
                local OnLeave = button:GetScript('OnLeave')
                button:SetScript('OnLeave', function()
                    local hotkey = _G[this:GetName() .. 'HotKey']
                    local name = _G[this:GetName() .. 'Name']

                    if hotkey then
                        hotkey:Hide()
                    end

                    if name then
                        name:Hide()
                    end

                    if OnLeave then
                        OnLeave()
                    end
                end)

                -- functions required by LibKeyBound
                button.GetHotkey = self.GetHotkey
                button.SetKey = self.SetKey
                button.GetBindings = self.GetBindings
                button.GetBindAction = self.GetBindAction
                button.ClearBindings = self.ClearBindings

                local hotkey = _G[buttonName .. i .. 'HotKey']
                local name = _G[buttonName .. i .. 'Name']
                local icon = _G[buttonName .. i .. 'Icon']

                -- initially hide hotkey/name
                if hotkey then
                    hotkey:Hide()
                end

                if name then
                    name:Hide()
                end

                -- change tex coord to remove the borders embedded into icon textures
                icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
            end
        end
    end
end

-- parse macros for UseItemByName
function f:UPDATE_MACROS()
    macroItems = {}

    local name, body, item
    for i = 1, 36 do
        name, _, body = GetMacroInfo(i)
        if name and body then
            item = match(body, 'UseItemByName%([\'"]([^\'"]+)[\'"]%)')

            if item then
                macroItems[name] = item
            end
        end
    end
end

local function UpdateItemMacro(button)
    if not button or not button.macroItem then
        return
    end

    local cooldown = _G[button:GetName() .. 'Cooldown']
    local iconTexture = _G[button:GetName() .. 'Icon']
    local countTexture = _G[button:GetName() .. 'Count']
    local bag, slot, count, texture = GetContainerItemByName(button.macroItem)

    -- icon texture and count
    if count and texture then
        eActionBars_IconCache[button.macroItem] = texture

        iconTexture:SetVertexColor(1.0, 1.0, 1.0)
        iconTexture:SetTexture(texture)
        countTexture:SetText(count)
    else
        iconTexture:SetVertexColor(0.4, 0.4, 0.4)
        iconTexture:SetTexture(eActionBars_IconCache[button.macroItem] or 'Interface\\Icons\\INV_Misc_QuestionMark')
        countTexture:SetText('0')
    end

    -- cooldown
    if bag and slot then
        local start, duration, enable = GetContainerItemCooldown(bag, slot)
        CooldownFrame_SetTimer(cooldown, start, duration, enable)
    end
end

-- update item counts and textures for macros that use UseItemByName
function f:BAG_UPDATE()
    local button
    for k in macroItemButtons do
        button = _G[k]
        if button.macroItem then
            UpdateItemMacro(button)
        else
            macroItemButtons[k] = nil
        end
    end
end

f.ACTIONBAR_UPDATE_COOLDOWN = f.BAG_UPDATE

function f:ADDON_LOADED(addon)
    if addon ~= 'eActionBars' then
        return
    end

    f:UnregisterEvent('ADDON_LOADED')

    -- show item icon/count/tooltip for macros that use UseItemByName
    eActionBars_IconCache = eActionBars_IconCache or {}
    post_hook('ActionButton_Update', function()
        local name = GetActionText(ActionButton_GetPagedID(this))
        if not name or not macroItems[name] then
            this.macroItem = nil
            return
        end

        macroItemButtons[this:GetName()] = true
        this.macroItem = macroItems[name]
        UpdateItemMacro(this)
    end)

    post_hook('ActionButton_UpdateUsable', function()
        UpdateItemMacro(this)

        -- change icon color to red if out of range
        local icon = _G[this:GetName() .. 'Icon']
        local normalTexture = _G[this:GetName() .. 'NormalTexture']
        local id = ActionButton_GetPagedID(this)
        local isUsable, notEnoughMana = IsUsableAction(id)
        if isUsable and IsActionInRange(id) == 0 then
            icon:SetVertexColor(1.0, 0.25, 0.25)
            normalTexture:SetVertexColor(1.0, 0.25, 0.25)
        end
    end)

    -- update out of range icon color properly
    replace_hook('ActionButton_OnUpdate', function(orig, elapsed)
        local changeRange = false
        if this.rangeTimer then
            if this.rangeTimer <= elapsed then
                local newRange = nil
                if IsActionInRange(ActionButton_GetPagedID(this)) == 0 then
                    newRange = true
                end

                if this.redRangeFlag ~= newRange then
                    this.redRangeFlag = newRange
                    changeRange = true
                end
            end
        end

        orig(elapsed)

        if changeRange then
            ActionButton_UpdateUsable()
        end
    end)

    -- change offsets for frames managed by UIParent
    UIPARENT_MANAGED_FRAME_POSITIONS['CONTAINER_OFFSET_X'].rightLeft = 30
    UIPARENT_MANAGED_FRAME_POSITIONS['CONTAINER_OFFSET_X'].rightRight = 30

    -- reset alpha of normal textures to 1 after hiding the grid
    post_hook('ActionButton_Update', function()
        if HasAction(ActionButton_GetPagedID(this)) then
            _G[this:GetName() .. 'NormalTexture']:SetAlpha(1)
        end
    end)

    post_hook('ActionButton_HideGrid', function(button)
        if not button then
            button = this
        end

        if HasAction(ActionButton_GetPagedID(button)) then
            _G[button:GetName() .. 'NormalTexture']:SetAlpha(1)
        end
    end)

    -- modify right side bar
    MultiBarRight:ClearAllPoints()
    MultiBarRight:SetPoint('RIGHT', UIParent, 'RIGHT')
    MultiBarRight:SetScale(0.8)

    -- modify left side bar
    MultiBarLeft:SetParent(MainMenuBar)

    -- make me horizontal~
    MultiBarLeftButton1:ClearAllPoints()
    MultiBarLeftButton1:SetPoint('TOPLEFT', MultiBarLeft, 'TOPLEFT')

    for i = 2, 12 do
        local button = _G['MultiBarLeftButton' .. i]
        button:ClearAllPoints()
        button:SetPoint('LEFT', _G['MultiBarLeftButton' .. i - 1], 'RIGHT', 6, 0)
    end

    -- resize and reposition
    MultiBarLeft:SetWidth(500)
    MultiBarLeft:SetHeight(38)
    MultiBarLeft:ClearAllPoints()
    MultiBarLeft:SetPoint('LEFT', ActionButton12, 'RIGHT', 14, -1)

    -- adjust bottom right bar position slightly. damn perfectionism..
    MultiBarBottomRight:SetPoint('LEFT', MultiBarBottomLeft, 'RIGHT', 12, 0)

    -- don't show grid even when ALWAYS_SHOW_MULTIBARS is 1
    MultiActionBar_ShowAllGrids = function()
        MultiActionBar_UpdateGrid('MultiBarBottomLeft', 1)
        MultiActionBar_UpdateGrid('MultiBarBottomRight', 1)
        MultiActionBar_UpdateGrid('MultiBarRight', 1)
    end

    MultiActionBar_HideAllGrids = function()
        MultiActionBar_UpdateGrid('MultiBarBottomLeft')
        MultiActionBar_UpdateGrid('MultiBarBottomRight')
        MultiActionBar_UpdateGrid('MultiBarRight')
    end

    -- show the left side bar no matter what
    post_hook('MultiActionBar_Update', function()
        MultiBarLeft:Show()
        VIEWABLE_ACTION_BAR_PAGES[LEFT_ACTIONBAR_PAGE] = nil
    end)

    -- hide stuff!
    local hideStuff = {
        'ActionBarUpButton',
        'ActionBarDownButton',

        'MainMenuBarPerformanceBarFrame',
        'MainMenuBarBackpackButton',
        'CharacterBag0Slot',
        'CharacterBag1Slot',
        'CharacterBag2Slot',
        'CharacterBag3Slot',
        'KeyRingButton',

        'MainMenuBarTexture2',
        'MainMenuBarTexture3',
        'MainMenuBarPageNumber',

        'CharacterMicroButton',
        'SpellbookMicroButton',
        'TalentMicroButton',
        'QuestLogMicroButton',
        'SocialsMicroButton',
        'WorldMapMicroButton',
        'MainMenuMicroButton',
        'HelpMicroButton'
    }

    for _, v in pairs(hideStuff) do
        local b = _G[v]

        b:Hide()
        b.Show = dummy
    end

    -- create some awesome new backgrounds
    local texLeft = MainMenuBarArtFrame:CreateTexture(nil, 'ARTWORK')
    local texRight = MainMenuBarArtFrame:CreateTexture(nil, 'ARTWORK')

    texLeft:SetTexture('Interface\\MainMenuBar\\UI-MainMenuBar-Dwarf')
    texLeft:SetTexCoord(0, 0.83203125, 0, 1, 1, 0.83203125, 1, 1)
    texLeft:SetWidth(256)
    texLeft:SetHeight(43)
    texLeft:SetPoint('BOTTOM', MainMenuBarArtFrame, 'BOTTOM', 128, 0)

    texRight:SetTexture('Interface\\MainMenuBar\\UI-MainMenuBar-Dwarf')
    texRight:SetTexCoord(0, 0.58203125, 0, 0.75, 1, 0.58203125, 1, 0.75)
    texRight:SetWidth(256)
    texRight:SetHeight(43)
    texRight:SetPoint('BOTTOM', MainMenuBarArtFrame, 'BOTTOM', 384, 0)
end

f:RegisterEvent('ADDON_LOADED')
f:RegisterEvent('PLAYER_LOGIN')
f:RegisterEvent('UPDATE_MACROS')
f:RegisterEvent('BAG_UPDATE')
f:RegisterEvent('ACTIONBAR_UPDATE_COOLDOWN')
f:SetScript('OnEvent', function()
    this[event](this, arg1)
end)

local f = CreateFrame('Frame')

-- skin the buff buttons!
local function skin_buff_button(name)
    local button = _G[name]
    local border = _G[name .. 'Border']
    local icon = _G[name .. 'Icon']
    local normal

    -- icon
    icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    icon:ClearAllPoints()
    icon:SetPoint('TOPLEFT', button, 'TOPLEFT', 2, -2)
    icon:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', -2, 2)

    -- debuff and tench border
    if border then
        border:SetTexture('Interface\\AddOns\\eBuffs\\border')
        border:SetTexCoord(0, 1, 0, 1)
        border:SetBlendMode('ADD')
        border:ClearAllPoints()
        border:SetPoint('TOPLEFT', icon, 'TOPLEFT', -11, 12)
        border:SetPoint('BOTTOMRIGHT', icon, 'BOTTOMRIGHT', 11, -11)

        -- default tench border texture is already colored, so apply a color here
        if name == 'TempEnchant1' or name == 'TempEnchant2' then
            border:SetVertexColor(0.7, 0.1, 0.8)
        end
    end

    -- normal border
    normal = button:CreateTexture(name .. 'Normal', 'BORDER')
    normal:SetTexture('Interface\\Buttons\\UI-Quickslot2')
    normal:SetPoint('TOPLEFT', icon, 'TOPLEFT', -11, 11)
    normal:SetPoint('BOTTOMRIGHT', icon, 'BOTTOMRIGHT', 11, -11)
end

function f:ADDON_LOADED(addon)
    if addon ~= 'eBuffs' then
        return
    end

    f:UnregisterEvent('ADDON_LOADED')

    skin_buff_button('TempEnchant1')
    skin_buff_button('TempEnchant2')

    for i = 0, 23 do
        skin_buff_button('BuffButton' .. i)
    end
end

f:RegisterEvent('ADDON_LOADED')
f:SetScript('OnEvent', function()
    this[event](this, arg1)
end)

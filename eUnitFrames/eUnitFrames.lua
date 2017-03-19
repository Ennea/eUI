local f = CreateFrame('Frame')
local dummy = function() return end

local function unit_frame_update(event)
    if event and event ~= 'PLAYER_ENTERING_WORLD' and event ~= 'VARIABLES_LOADED' and event ~= 'UNIT_NAME_UPDATE' then
        return
    end

    -- class colored name
    local class = select(2, UnitClass(this.unit))
    if class and UnitIsPlayer(this.unit) then
        local t = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
        local col = format('|cff%2x%2x%2x', t.r * 255, t.g * 255, t.b * 255)
        this.name:SetText(col .. GetUnitName(this.unit) .. '|r')
    end
end

local function target_tapped_update()
    if UnitIsTapped('target') and not UnitIsTappedByPlayer('target') then
        TargetFrameNameBackground:Show()
    else
        TargetFrameNameBackground:Hide()
    end
end

function f:ADDON_LOADED(addon)
    if addon ~= 'eUnitFrames' then
        return
    end

    f:UnregisterEvent('ADDON_LOADED')

    PlayerHitIndicator:Hide()
    PlayerHitIndicator.Show = dummy

    -- only show TargetFrameNameBackground when target is tappable and not tapped by you
    post_hook('TargetFrame_CheckFaction', target_tapped_update)

    -- elite texture for PlayerFrame
    PlayerFrameTexture:SetTexture('Interface\\TargetingFrame\\UI-TargetingFrame-Elite')

    -- change mana color
    ManaBarColor[0].r = 0.2
    ManaBarColor[0].g = 0.5
    ManaBarColor[0].b = 1

    -- hook uf updates to apply class colors to unit names
    post_hook('UnitFrame_Update', function()
        unit_frame_update()
    end)

    post_hook('UnitFrame_OnEvent', function()
        unit_frame_update(event)
    end)
end

f:RegisterEvent('ADDON_LOADED')
f:SetScript('OnEvent', function()
    this[event](this, arg1)
end)

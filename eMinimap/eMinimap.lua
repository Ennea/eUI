local f = CreateFrame('Frame')
local zoneTextFrame
local format = string.format

-- get and set the zone text, including pvp zone color
local function update_zone_text()
    if not zoneTextFrame then
        return
    end

    local zone = GetSubZoneText()
    zone = (zone == '') and GetRealZoneText() or zone
    zone = zone or ''  -- can't remember if this is still required. leaving it in regardless

    local pvp = GetZonePVPInfo()
    local col = {
        ['friendly'] = '00FF00',
        ['hostile'] = 'FF2000'
    }
    local c = col[pvp] or 'FFFF00'

    zone = format('|cff%s%s|r', c, zone)
    zoneTextFrame.zoneText:SetText(zone)
    zoneTextFrame.helper:SetText(zone)
    if GameTooltip:IsOwned(zoneTextFrame) then
        GameTooltip:SetText(zone)
    end
end

function f:ADDON_LOADED(addon)
    if addon ~= 'eMinimap' then
        return
    end

    f:UnregisterEvent('ADDON_LOADED')

    -- hide various frames and textures
    local hideFrames = {
        MinimapZoomIn,
        MinimapZoomOut,
        MinimapZoneText,
        MinimapBorderTop,
        MinimapToggleButton,
        MinimapZoneTextButton
    }

    for _, v in pairs(hideFrames) do
        v:Hide()
    end

    -- add ping and addon memory usage display to GameTimeFrame tooltip
    post_hook('GameTimeFrame_UpdateTooltip', function()
        local _, _, latency = GetNetStats()
        GameTooltip:AddLine(format('%d ms', latency))
        GameTooltip:AddLine(format('%d MB', gcinfo() / 1024))
        GameTooltip:Show()
    end)

    -- mouse wheel zooming
    Minimap:EnableMouseWheel(true)
    Minimap:SetScript('OnMouseWheel', function()
        if (arg1 > 0) then
            Minimap_ZoomIn()
        else
            Minimap_ZoomOut()
        end
    end)

    -- adjust minimap position to accomodate for the new zone text
    MinimapCluster:ClearAllPoints()
    MinimapCluster:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', 0, -4)

    -- zone text display
    zoneTextFrame = CreateFrame('Frame', nil, MinimapCluster)
    zoneTextFrame:SetWidth(120)
    zoneTextFrame:SetHeight(20)
    zoneTextFrame:SetPoint('BOTTOM', Minimap, 'TOP', 0, 8)
    zoneTextFrame:EnableMouse(true) -- required for tooltip hover

    local zoneText = zoneTextFrame:CreateFontString(nil, 'OVERLAY')
    zoneText:SetFont('Fonts\\FRIZQT__.TTF', 12, 'OUTLINE')
    zoneText:SetWidth(120)
    zoneText:SetHeight(12)
    zoneText:SetPoint('BOTTOM', zoneTextFrame, 'BOTTOM')

    -- we use this to determine the true length of the current zone text,
    -- since in 1.12.1, GetStringWidth() will not return the 'true' width,
    -- but the truncated one
    local helper = zoneTextFrame:CreateFontString()
    helper:SetFont('Fonts\\FRIZQT__.TTF', 12, 'OUTLINE')
    helper:SetWidth(1024)
    helper:SetAlpha(0)

    zoneTextFrame.zoneText = zoneText
    zoneTextFrame.helper = helper

    zoneTextFrame:SetScript('OnEnter', function()
        if this.helper:GetStringWidth() < 120 then
            return
        end

        GameTooltip:SetOwner(this, 'ANCHOR_PRESERVE')
        GameTooltip:SetText(this.zoneText:GetText())

        GameTooltip:ClearAllPoints()
        GameTooltip:SetPoint('BOTTOM', zoneTextFrame, 'BOTTOM')
    end)

    zoneTextFrame:SetScript('OnLeave', function()
        if GameTooltip:IsOwned(this) then
            GameTooltip:Hide()
        end
    end)

    -- initial update
    update_zone_text()
end

function f:ZONE_CHANGED()
    update_zone_text()
end

function f:ZONE_CHANGED_INDOORS()
    update_zone_text()
end

function f:ZONE_CHANGED_NEW_AREA()
    update_zone_text()
end

f:RegisterEvent('ADDON_LOADED')
f:RegisterEvent('ZONE_CHANGED')
f:RegisterEvent('ZONE_CHANGED_INDOORS')
f:RegisterEvent('ZONE_CHANGED_NEW_AREA')

f:SetScript('OnEvent', function()
    this[event](this, arg1)
end)

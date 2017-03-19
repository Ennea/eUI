local f = CreateFrame('Frame')
local dummy = function() return end
local playerCoords, mouseCoords

local format = string.format
local min = math.min
local max = math.max

local function get_scale()
    if GetCVar('useUIScale') == '1' then
        return 0.83333 * GetCVar('UIScale')
    else
        return 0.75
    end
end

local function update_coords()
    -- hide coords if not in regional map mode
    if not playerCoords:IsVisible() and WorldMapZoneDropDown.selectedID then
        playerCoords:Show()
        mouseCoords:Show()
    elseif not WorldMapZoneDropDown.selectedID then
        playerCoords:Hide()
        mouseCoords:Hide()
    end

    local wms = get_scale() * WorldMapDetailFrame:GetScale()
    local wmw, wmh = WorldMapDetailFrame:GetWidth() * wms, WorldMapDetailFrame:GetHeight() * wms
    local cx, cy = WorldMapDetailFrame:GetCenter()
    local wml, wmb = WorldMapDetailFrame:GetLeft() * wms, WorldMapDetailFrame:GetBottom() * wms
    local px, py = GetPlayerMapPosition('player')
    local mx, my = GetCursorPosition()

    mx = (mx - wml) / wmw * 100
    my = 100 - (my - wmb) / wmh * 100

    mx = max(0, min(100, mx))
    my = max(0, min(100, my))

    playerCoords:SetText(format('Player: %.1f, %.1f', px * 100, py * 100))
    mouseCoords:SetText(format('Mouse: %.1f, %.1f', mx, my))
end

function f:ADDON_LOADED(addon)
    if addon ~= 'eMap' then
        return
    end

    f:UnregisterEvent('ADDON_LOADED')

    -- hide black backdrop
    BlackoutWorld:Hide()

    -- hide mag button
    WorldMapMagnifyingGlassButton:Hide()
    WorldMapMagnifyingGlassButton.Show = dummy

    -- world map scale and enable keyboard while map is open
    post_hook(WorldMapFrame, 'Show', function(self)
        self:SetScale(get_scale())
        self:EnableKeyboard(false)
    end)

    -- don't hide stuff when the map is open
    UIPanelWindows['WorldMapFrame'] = {
        area = 'center',
        pushable = 0
    }

    -- reposition the map slightly
    -- width and height need to be set, otherwise the position can't be changed
    WorldMapFrame:SetWidth(1024)
    WorldMapFrame:SetHeight(768)
    WorldMapFrame:ClearAllPoints()
    WorldMapFrame:SetPoint('CENTER', UIParent, 'CENTER', 0, 30)

    -- create coord text
    playerCoords = WorldMapFrame:CreateFontString(nil, 'ARTWORK')
    playerCoords:SetPoint('TOPLEFT', WorldMapFrame, 'BOTTOMLEFT', 20, 22)
    playerCoords:SetFontObject('GameFontNormal')
    playerCoords:SetJustifyH('LEFT')
    playerCoords:SetText('Player:')

    mouseCoords = WorldMapFrame:CreateFontString(nil, 'ARTWORK')
    mouseCoords:SetPoint('TOPLEFT', WorldMapFrame, 'BOTTOMLEFT', 180, 22)
    mouseCoords:SetFontObject('GameFontNormal')
    mouseCoords:SetJustifyH('LEFT')
    mouseCoords:SetText('Mouse:')

    -- coord updates
    local elapsed = 0
    post_hook(WorldMapFrame, 'Show', function(self)
        self:SetScript('OnUpdate', function()
            elapsed = elapsed + arg1
            if elapsed >= 0.05 then
                update_coords()
                elapsed = elapsed - 0.05
            end
        end)
    end)

    post_hook(WorldMapFrame, 'Hide', function(self)
        self:SetScript('OnUpdate', nil)
    end)
end

f:RegisterEvent('ADDON_LOADED')
f:SetScript('OnEvent', function()
    this[event](this, arg1)
end)

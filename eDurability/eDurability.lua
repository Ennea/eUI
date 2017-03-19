local f = CreateFrame('Frame', nil, PaperDollFrame)
local durabilityText
local tooltip

local format = string.format
local match = string.match
local floor = math.floor
local modf = math.modf

-- http://www.wowwiki.com/ColorGradient, altered
local function ColorGradient(perc)
    local red1, red2, green2, green3 = 1, 1, 1, 1
    local red3, green1 = 0, 0

    if perc >= 1 then
        local r, g = red3, green3
        return r, g
    elseif perc <= 0 then
        local r, g = red1, green1
        return r, g
    end

    local segment, relperc = modf(perc * 2)
    local r1, g1, r2, g2 = select(segment * 2 + 1, red1, green1, red2, green2, red3, green3)

    return r1 + (r2 - r1) * relperc, g1 + (g2 - g1) * relperc
end

-- update the durability text
local function update_durability_text()
    local currentDurability = 0
    local totalDurability = 0
    local text, hasItem
    local d, td

    for i = 1, 18 do
        hasItem = tooltip:SetInventoryItem('player', i)

        if hasItem then
            -- iterate over all tooltip lines to find item durability
            for k = 1, 30 do
                text = _G['eDurabilityTooltipTextLeft' .. k]:GetText()

                if not text then
                    break
                end

                d, td = string.match(text, '(%d+) / (%d+)$')
                if d and td then
                    currentDurability = currentDurability + tonumber(d)
                    totalDurability = totalDurability + tonumber(td)
                    break
                end
            end
        end
    end

    local percent = currentDurability / totalDurability
    local red, green = ColorGradient(percent)
    durabilityText:SetText(format('|cff%2x%2x00%d%%|r', red * 255, green * 255, floor(percent * 100)))
end

-- initialize the whole thing
function f:ADDON_LOADED(addon)
    if addon ~= 'eDurability' then
        return
    end

    f:UnregisterEvent('ADDON_LOADED')

    f:SetWidth(48)
    f:SetHeight(24)
    f:SetPoint('BOTTOMRIGHT', CharacterFrame, 'BOTTOMRIGHT', -46, 86)
    f:SetScript('OnShow', update_durability_text)

    durabilityText = f:CreateFontString('OVERLAY')
    durabilityText:SetFontObject(GameFontNormal)
    durabilityText:SetJustifyH('RIGHT')
    durabilityText:SetWidth(48)
    durabilityText:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT')

    tooltip = CreateFrame('GameTooltip', 'eDurabilityTooltip', nil, 'GameTooltipTemplate')
    tooltip:SetOwner(UIParent, 'ANCHOR_NONE')
end

f:RegisterEvent('ADDON_LOADED')
f:SetScript('OnEvent', function()
    this[event](this, arg1)
end)

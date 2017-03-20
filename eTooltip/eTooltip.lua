local f = CreateFrame('Frame')
local factions = {}
local dummy = function() end

local round = math.round
local format = string.format
local match = string.match
local insert = table.insert

-- set and show a tooltip's icon
local function show_icon(self, icon, fixHeight)
    if not self.icon then
        return
    end

    local padding = self.padding and self.padding + 20 or 20
    local textLeft1 = _G[self:GetName() .. 'TextLeft1']
    local textLeft2 = _G[self:GetName() .. 'TextLeft2']
    local textRight1 = _G[self:GetName() .. 'TextRight1']

    if not icon then
        self:HideIcon()
    else
        -- update width if necessary
        -- accounting for icon and overlapping textLeft1 and textRight1
        local minWidth = textLeft1:GetWidth() + 30 + (textRight1:IsShown() and textRight1:GetWidth() or 0)
        if (self:GetWidth() - padding) < minWidth then  -- accounting for padding
            self:SetMinimumWidth(minWidth)
            self:Show()
        end

        -- update height
        self:SetHeight(self:GetHeight() + 10)
        self.fixHeight = fixHeight or false

        -- show icon and change anchors to account for it
        self.icon:SetTexture(icon)
        self.icon:Show()
        textLeft1:SetPoint('TOPLEFT', self.icon, 'TOPRIGHT', 5, -5)
        textLeft2:SetPoint('TOPLEFT', self.icon, 'BOTTOMLEFT', 0, -2)

        local offset = select(4, textRight1:GetPoint(1))
        textRight1:SetPoint('RIGHT', textLeft1, 'LEFT', offset - 30, 0)
    end
end

-- hide a tooltip's icon
local function hide_icon(self)
    if not self.icon or not self.icon:IsShown() then
        return
    end

    local textLeft1 = _G[self:GetName() .. 'TextLeft1']
    local textLeft2 = _G[self:GetName() .. 'TextLeft2']

    self.icon:Hide()
    textLeft1:SetPoint('TOPLEFT', self, 'TOPLEFT', 10, -10)
    textLeft2:SetPoint('TOPLEFT', textLeft1, 'BOTTOMLEFT', 0, -2)
end

-- change insets to 4 from 5 to fix backdrops that are too small
local function fix_insets(tooltip)
    local backdrop = tooltip:GetBackdrop()
    local r, g, b, a = tooltip:GetBackdropColor()

    backdrop.insets.top = 4
    backdrop.insets.left = 4
    backdrop.insets.right = 4
    backdrop.insets.bottom = 4

    tooltip:SetBackdrop(backdrop)
    tooltip:SetBackdropColor(r, g, b, a)  -- also set color, for any custom tooltips
end

-- create an icon texture, add a few functions, do some tweaking
local function initialize_tooltip(tooltip)
    if not tooltip then
        return
    end

    tooltip.icon = tooltip:CreateTexture(nil, 'ARTWORK')
    tooltip.icon:SetWidth(24)
    tooltip.icon:SetHeight(24)
    tooltip.icon:SetPoint('TOPLEFT', tooltip, 'TOPLEFT', 10, -10)

    tooltip.ShowIcon = show_icon
    tooltip.HideIcon = hide_icon

    -- decorate status bar
    local bar = _G[tooltip:GetName() .. 'StatusBar']
    if bar then
        bar:ClearAllPoints()
        bar:SetPoint('TOPLEFT', tooltip, 'BOTTOMLEFT', 6, -4)
        bar:SetPoint('TOPRIGHT', tooltip, 'BOTTOMRIGHT', -6, -4)
        bar.elapsed = 0

        local background = CreateFrame('Frame', nil, bar)
        background:SetPoint('TOPLEFT', bar, 'TOPLEFT', -3, 3)
        background:SetPoint('BOTTOMRIGHT', bar, 'BOTTOMRIGHT', 3, -3)
        background:SetFrameLevel(1)

        background:SetBackdrop({
            bgFile = 'Interface\\Tooltips\\UI-Tooltip-Background',
            edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
            tile = true, tileSize = 10, edgeSize = 10,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        background:SetBackdropColor(0, 0, 0)

        bar:SetScript('OnUpdate', function()
            this.elapsed = this.elapsed + arg1
            if this.elapsed >= 0.05 then
                this.elapsed = 0

                if this:IsVisible() and this:GetValue() == 0 then
                    this:Hide()
                end
            end
        end)

        bar:SetScript('OnShow', function()
            if this:IsVisible() and this:GetValue() == 0 then
                this:Hide()
            end
        end)
    end

    fix_insets(tooltip)
end

local function tooltip_clear_lines(tooltip)
    tooltip.lineCounter = 1
end

-- a method that uses a tooltip's own AddLine for new lines, but modifies
-- an existing line's text if it's already visible, to prevent having to
-- re-implement tooltip health bars
local function tooltip_add_line(tooltip, text, r, g, b)
    if not tooltip.lineCounter or tooltip.lineCounter > 30 then
        return
    end

    if not r or not g or not b then
        r = 1
        g = 1
        b = 1
    end

    -- workaround for non-mouseover tooltips' first
    -- line's color being overwritten again
    if tooltip.lineCounter == 1 then
        text = format('|cff%02x%02x%02x%s|r', r * 255, g * 255, b * 255, text)
    end

    local line = _G[tooltip:GetName() .. 'TextLeft' .. tooltip.lineCounter]
    if line:IsVisible() then
        line:SetText(text)
        line:SetTextColor(r, g, b)
    else
        tooltip:AddLine(text, r, g, b)
    end

    tooltip.lineCounter = tooltip.lineCounter + 1
end

-- cache all known factions
local function update_faction_cache()
    factions = {}
    for i = 1, GetNumFactions() do
        local name, _, _, _, _, _, _, _, isHeader = GetFactionInfo(i)
        if not isHeader then
            insert(factions, name)
        end
    end
end

-- get a unit's reaction color
-- taken from GameTooltip.lua, modified
function get_unit_color(unit)
    local r, g, b
    if UnitPlayerControlled(unit) then
        if UnitCanAttack(unit, 'player') then
            -- Hostile players are red
            if not UnitCanAttack('player', unit) then
                r = 0.6
                g = 0.6
                b = 1.0
            else
                r = FACTION_BAR_COLORS[2].r
                g = FACTION_BAR_COLORS[2].g
                b = FACTION_BAR_COLORS[2].b
            end
        elseif UnitCanAttack('player', unit) then
            -- Players we can attack but which are not hostile are yellow
            r = FACTION_BAR_COLORS[4].r
            g = FACTION_BAR_COLORS[4].g
            b = FACTION_BAR_COLORS[4].b
        elseif UnitIsPVP(unit) then
            -- Players we can assist but are PvP flagged are green
            r = FACTION_BAR_COLORS[6].r
            g = FACTION_BAR_COLORS[6].g
            b = FACTION_BAR_COLORS[6].b
        else
            -- All other players are blue (the usual state on the "blue" server)
            r = 0.6
            g = 0.6
            b = 1.0
        end
    else
        local reaction = UnitReaction(unit, 'player')
        if reaction then
            r = FACTION_BAR_COLORS[reaction].r
            g = FACTION_BAR_COLORS[reaction].g
            b = FACTION_BAR_COLORS[reaction].b
        else
            r = 0.6
            g = 0.6
            b = 1.0
        end
    end

    return { r = r, g = g, b = b }
end

function update_unit_tooltip(self, unit)
    if not UnitExists(unit) then
        return
    end

    self.unit = unit

    -- parse the existing tooltip for information we don't have access to otherwise
    -- this is currently:
    -- faction (Stormwind, Ironforge, ...)
    -- pet/minion flavor text
    -- whether the unit is skinnable
    -- whether the unit is resurrectable
    -- the unit's "title" (King of Stormwind, Weapons Merchant, ...)
    local faction, title, zone
    local skinnable, skinnableColor, resurrectable, resurrectableColor
    local extraLines = {}

    local unitIsPartyOrRaid = match(unit, '^%a+') == 'party' or match(unit, '^%a+') == 'raid'

    for i = 2, 30 do
        local line = _G[self:GetName() .. 'TextLeft' .. i]
        local text = line:GetText()

        -- no more lines to parse
        if not text then
            break
        end

        -- unit is skinnable
        if text == UNIT_SKINNABLE then
            skinnable = true
            local r, g, b = line:GetTextColor()
            skinnableColor = {
                r = round(r, 0.01),
                g = round(g, 0.01),
                b = round(b, 0.01)
            }

        -- unit is resurrectable
        elseif text == RESURRECTABLE then
            resurrectable = true
            local r, g, b = line:GetTextColor()
            resurrectableColor = {
                r = round(r, 0.01),
                g = round(g, 0.01),
                b = round(b, 0.01)
            }

        -- just a level, ignore
        elseif match(text, '^%S*') == LEVEL then

        -- pvp is enabled, ignore
        elseif text == PVP_ENABLED then

        -- everything else
        else
            local factionFound = false

            -- check if the current line is a faction we know
            if not faction then
                for _, v in factions do
                    if text == v then
                        faction = v
                        factionFound = true
                        break
                    end
                end
            end

            -- not a faction. try to parse everything we can't grab directly
            if not factionFound then
                -- title
                if i == 2 then
                    title = text

                -- probably zone text
                elseif unitIsPartyOrRaid then
                    zone = text

                -- must be something we don't account for yet. print
                else
                    -- could be a (yet unknown) faction
                    -- if not faction then
                    --     faction = text

                    -- if we already have a faction, it's something we're not accounting for (yet)
                    -- since this could be something like Questie's added tooltip info as well,
                    -- just capture it and add it to the end of the tooltip
                    -- else
                        local r, g, b = line:GetTextColor()
                        insert(extraLines, {
                            text = text,
                            r = r,
                            g = g,
                            b = b
                        })
                    -- end
                end
            end
        end
    end

    -- collect info
    local guild, className, class, race, creatureType, creatureFamily, reaction, levelColor
    local name, rank = UnitName(unit), GetPVPRankInfo(UnitPVPRank(unit), unit)
    local nameColor = get_unit_color(unit)
    local level = UnitLevel(unit)
    local classification = UnitClassification(unit)
    if classification == 'worldboss' then
        classification = BOSS
    elseif classification == 'rareelite' then
        classification = format('%s %s', ITEM_QUALITY3_DESC, ELITE)
    elseif classification == 'elite' then
        classification = ELITE
    elseif classification == 'rare' then
        classification = ITEM_QUALITY3_DESC
    else
        classification = nil
    end

    -- player only info
    if UnitIsPlayer(unit) then
        className, class = UnitClass(unit)
        race = UnitRace(unit)
        guild = GetGuildInfo(unit)

        local c = RAID_CLASS_COLORS[class]
        className = format('|cff%02x%02x%02x%s|r', c.r * 255, c.g * 255, c.b * 255, className)

    -- non-player info
    else
        reaction = UnitReaction(unit, 'player')
        -- color level if player can attack unit
        if UnitCanAttack('player', unit) then
            levelColor = GetDifficultyColor(level == -1 and 100 or level)
        end

        if UnitIsDead(unit) then
            creatureType = CORPSE
        else
            creatureType = UnitCreatureType(unit)
            creatureFamily = UnitCreatureFamily(unit)
            creatureType = creatureFamily and creatureFamily or creatureType
        end
    end

    -- clear the tooltip, then fill it with new info
    tooltip_clear_lines(self)

    -- pvp rank and name
    if rank then
        tooltip_add_line(self, format('%s %s', rank, name), nameColor.r, nameColor.g, nameColor.b)
    else
        tooltip_add_line(self, name, nameColor.r, nameColor.g, nameColor.b)
    end

    -- title
    if title then
        tooltip_add_line(self, title, 0.6, 0.6, 0.6)
    end

    -- guild
    if guild then
        tooltip_add_line(self, format('<%s>', guild), 0.6, 0.6, 0.6)
    end

    -- level, classification, race and class
    level = level == -1 and '??' or level
    if levelColor then
        level = format('|cff%02x%02x%02x%s|r', levelColor.r * 255, levelColor.g * 255, levelColor.b * 255, level)
    end

    if UnitIsPlayer(unit) then
        tooltip_add_line(self, format('%s %s %s %s', LEVEL, level, race, className))
    elseif classification then
        if creatureType then
            tooltip_add_line(self, format('%s %s %s (%s)', LEVEL, level, creatureType, classification))
        else
            tooltip_add_line(self, format('%s %s (%s)', LEVEL, level, classification))
        end
    else
        if creatureType then
            tooltip_add_line(self, format('%s %s %s', LEVEL, level, creatureType))
        else
            tooltip_add_line(self, format('%s %s', LEVEL, level))
        end
    end

    -- faction
    if faction then
        tooltip_add_line(self, faction)
    end

    -- pvp enabled
    if UnitIsPVP(unit) then
        tooltip_add_line(self, PVP_ENABLED)
    end

    -- zone text (far away party and raid members)
    if zone then
        tooltip_add_line(self, zone)
    end

    -- skinnable
    if skinnable then
        tooltip_add_line(self, UNIT_SKINNABLE, skinnableColor.r, skinnableColor.g, skinnableColor.b)
    end

    -- resurrectable
    if resurrectable then
        tooltip_add_line(self, RESURRECTABLE, resurrectableColor.r, resurrectableColor.g, resurrectableColor.b)
    end

    -- any extra lines
    for _, v in pairs(extraLines) do
        tooltip_add_line(self, v.text, v.r, v.g, v.b)
    end

    -- force recalculation of width and height
    self:Show()
end

-- account for the X button in the ItemRefTooltip
ItemRefTooltip.padding = 16

-- hide icon when hiding the tooltip
post_hook('GameTooltip_OnHide', function()
    if this.HideIcon then
        this:HideIcon()
    end
end)

-- default tooltips. add icons and change unit tooltip content
local tooltips = { GameTooltip, ItemRefTooltip }
for _, tooltip in tooltips do
    initialize_tooltip(tooltip)

    post_hook(tooltip, 'Show', function(self)
        if self.fixHeight then
            self:SetHeight(self:GetHeight() + 10)
            self.fixHeight = false
        end

        self:SetBackdropColor(0, 0, 0, 1)
    end)

    -- hook a ton of functions to add item and spell icons to tooltips
    post_hook(tooltip, 'SetAction', function(self, slot)
        local icon = GetActionTexture(slot)
        self:ShowIcon(icon)
    end)

    post_hook(tooltip, 'SetAuctionItem', function(self, type, index)
        local icon = select(2, GetAuctionItemInfo(type, index))
        self:ShowIcon(icon)
    end)

    post_hook(tooltip, 'SetAuctionSellItem', function(self, type, index)
        local icon = select(2, GetAuctionSellItemInfo(type, index))
        self:ShowIcon(icon)
    end)

    post_hook(tooltip, 'SetBagItem', function(self, bag, slot)
        local icon = GetContainerItemInfo(bag, slot)
        self:ShowIcon(icon)
    end)

    post_hook(tooltip, 'SetBuybackItem', function(self, type, index)
        local icon = select(2, GetBuybackItemInfo(type, index))
        self:ShowIcon(icon)
    end)

    post_hook(tooltip, 'SetCraftItem', function(self, index)
        local id = GetCraftItemLink(index)
        if id then
            local icon = select(9, GetItemInfo(id))
            self:ShowIcon(icon)
        end
    end)

    post_hook(tooltip, 'SetHyperlink', function(self, link)
        local icon = select(9, GetItemInfo(link))
        self:ShowIcon(icon)
    end)

    post_hook(tooltip, 'SetInboxItem', function(self, index)
        local icon = select(2, GetInboxItem(index))
        self:ShowIcon(icon, true)
    end)

    -- SetInventoryItem can't be hooked, it will not show any tooltip at all

    post_hook(tooltip, 'SetLootItem', function(self, slot)
        local icon = GetLootSlotInfo(slot)
        self:ShowIcon(icon, true)
    end)

    post_hook(tooltip, 'SetLootRollItem', function(self, id)
        local icon = GetLootRollItemInfo(id)
        self:ShowIcon(icon)
    end)

    post_hook(tooltip, 'SetMerchantItem', function(self, type, index)
        local icon = select(2, GetMerchantItemInfo(type, index))
        self:ShowIcon(icon)
    end)

    post_hook(tooltip, 'SetPetAction', function(self, slot)
        local icon = select(3, GetPetActionInfo(slot))
        self:ShowIcon(icon)
    end)

    post_hook(tooltip, 'SetPlayerBuff', function(self, index)
        local icon = GetPlayerBuffTexture(index)
        self:ShowIcon(icon)
    end)

    post_hook(tooltip, 'SetQuestItem', function(self, type, index)
        local icon = select(2, GetQuestItemInfo(type, index))
        self:ShowIcon(icon)
    end)

    post_hook(tooltip, 'SetQuestLogItem', function(self, type, index)
        local id = match(GetQuestLogItemLink(type, index), 'item:(%d+)')
        if id then
            local icon = select(9, GetItemInfo(id))
            self:ShowIcon(icon)
        end
    end)

    post_hook(tooltip, 'SetSendMailItem', function(self)
        local icon = select(2, GetSendMailItem())
        self:ShowIcon(icon)
    end)

    post_hook(tooltip, 'SetShapeShift', function(self, index)
        local icon = GetShapeshiftFormInfo(index)
        self:ShowIcon(icon)
    end)

    post_hook(tooltip, 'SetSpell', function(self, id, book)
        local icon = GetSpellTexture(id, book)
        self:ShowIcon(icon)
    end)

    post_hook(tooltip, 'SetTalent', function(self, tabIndex, talentIndex)
        local icon = select(2, GetTalentInfo(tabIndex, talentIndex))
        self:ShowIcon(icon)
    end)

    post_hook(tooltip, 'SetTrackingSpell', function(self)
        local icon = GetTrackingTexture()
        self:ShowIcon(icon)
    end)

    post_hook(tooltip, 'SetTradePlayerItem', function(self, id)
        local icon = select(2, GetTradePlayerItemInfo(id))
        self:ShowIcon(icon)
    end)

    post_hook(tooltip, 'SetTradeSkillItem', function(self, ...)
        local id
        if getn(arg) == 1 then
            id = match(GetTradeSkillItemLink(unpack(arg)), 'item:(%d+)')
        elseif getn(arg) == 2 then
            id = match(GetTradeSkillReagentItemLink(unpack(arg)), 'item:(%d+)')
        end

        if id then
            local icon = select(9, GetItemInfo(id))
            self:ShowIcon(icon)
        end
    end)

    post_hook(tooltip, 'SetTradeTargetItem', function(self, id)
        local icon = select(2, GetTradeTargetItemInfo(id))
        self:ShowIcon(icon)
    end)

    post_hook(tooltip, 'SetTrainerService', function(self, id)
        local icon = GetTrainerServiceIcon(id)
        self:ShowIcon(icon, true)
    end)

    post_hook(tooltip, 'SetUnitBuff', function(self, unit, index)
        local icon = UnitBuff(unit, index)
        self:ShowIcon(icon)
    end)

    post_hook(tooltip, 'SetUnitDebuff', function(self, unit, index)
        local icon = UnitDebuff(unit, index)
        self:ShowIcon(icon)
    end)

    -- hook set unit to alter unit tooltip content
    post_hook(tooltip, 'SetUnit', update_unit_tooltip)
end

-- custom tooltips. fix insets
local tooltips = {
    ComparisonTooltip1,  -- EquipCompare
    ComparisonTooltip2  -- EquipCompare
}

for _, tooltip in tooltips do
    if tooltip then
        fix_insets(tooltip)
    end
end

function f:UPDATE_FACTION()
    update_faction_cache()
end

function f:UPDATE_MOUSEOVER_UNIT()
    update_unit_tooltip(GameTooltip, 'mouseover')
end

f:RegisterEvent('UPDATE_FACTION')
f:RegisterEvent('UPDATE_MOUSEOVER_UNIT')
f:SetScript('OnEvent', function()
    this[event](this, arg1)
end)

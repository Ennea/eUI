local f = CreateFrame('Frame')
local tooltip

function f:ADDON_LOADED(addon)
    if addon == 'Blizzard_AuctionUI' then
        -- FEATURE: tint icons of recipes that you already know on the AH
        post_hook('AuctionFrameBrowse_Update', function()
            local offset = FauxScrollFrame_GetOffset(BrowseScrollFrame)
            local alreadyKnown

            for i = 1, NUM_BROWSE_TO_DISPLAY do
                alreadyKnown = false
                tooltip:SetAuctionItem('list', offset + i)

                -- iterate over all tooltip lines to check whether the
                -- "Already known" phrase can be found in any of them
                for k = 1, 30 do
                    text = _G['QoLITooltipTextLeft' .. k]:GetText()

                    if not text then
                        break
                    end

                    if string.match(text, ITEM_SPELL_KNOWN) then
                        alreadyKnown = true
                        break
                    end
                end

                if alreadyKnown then
                    _G['BrowseButton' .. i .. 'ItemIconTexture']:SetVertexColor(0.4, 0.4, 0.4)
                end
            end
        end)
    end

    if addon ~= 'QoLI' then
        return
    end

    tooltip = CreateFrame('GameTooltip', 'QoLITooltip', nil, 'GameTooltipTemplate')
    tooltip:SetOwner(UIParent, 'ANCHOR_NONE')

    -- FEATURE: allow quick "looting" of mail attachments by holding down shift
    post_hook(OpenMailFrame, 'Show', function(self)
        if not IsShiftKeyDown() then
            return
        end

        -- money and items only. nobody needs the letters.. right?
        if OpenMailMoneyButton:IsVisible() then
            OpenMailMoneyButton:Click()
        end

        if OpenMailPackageButton:IsVisible() then
            OpenMailPackageButton:Click()
        end
    end)
end

-- FIX: QUEST_WATCH_LIST not being cleaned up when completing quests, leading to
-- an inability to track the maximum of 5 quests after completing tracked ones
function f:QUEST_COMPLETE()
    if getn(QUEST_WATCH_LIST) == 0 then
        return
    end

    local title = GetTitleText()
    if not title then
        return
    end

    for i = 1, getn(QUEST_WATCH_LIST) do
        if title == GetQuestLogTitle(QUEST_WATCH_LIST[i].index) then
            table.remove(QUEST_WATCH_LIST, i)
            break
        end
    end
end

f:RegisterEvent('ADDON_LOADED')
f:RegisterEvent('QUEST_COMPLETE')
f:SetScript('OnEvent', function()
    this[event](this, arg1)
end)

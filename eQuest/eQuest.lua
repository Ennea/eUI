local f = CreateFrame('Frame')
local format = string.format

function f:ADDON_LOADED(addon)
    if addon ~= 'eQuest' then
        return
    end

    f:UnregisterEvent('ADDON_LOADED')

    -- add quest levels to quest log
    post_hook('QuestLog_Update', function()
        local numEntries = GetNumQuestLogEntries()
        if numEntries == 0 then
            return
        end

        local questIndex, questLogTitle, questCheck
        local title, level, _, isHeader
        for i = 1, QUESTS_DISPLAYED do
            questIndex = i + FauxScrollFrame_GetOffset(QuestLogListScrollFrame)
            questLogTitle = getglobal('QuestLogTitle' .. i)
            questCheck = getglobal('QuestLogTitle' .. i .. 'Check')

            if questIndex <= numEntries then
                title, level, _, isHeader = GetQuestLogTitle(questIndex)

                if not isHeader then
                    -- add level to quest name
                    questLogTitle:SetText(format('[%d] %s', level, title))

                    -- place watch checkmark on the left side
                    questCheck:ClearAllPoints()
                    questCheck:SetPoint('RIGHT', questLogTitle, 'LEFT', 18, 0)
                end
            end
        end
    end)
end

f:RegisterEvent('ADDON_LOADED')
f:SetScript('OnEvent', function()
    this[event](this, arg1)
end)

local addonName, A = ...
local f = CreateFrame('Frame')
A.events = f
local journalQueued = false
function A.QueueJournal()
    if journalQueued then return end
    journalQueued = true
    C_Timer.After(1, function() if A.char then A.Provider.ReadJournal(); A.Refresh() end end)
    C_Timer.After(3, function()
        journalQueued = false
        if A.char then A.Provider.ReadJournal(); A.Refresh() end
    end)
end
function A.RefreshBuffs()
    A.buffs = A.Provider.Buffs()
    local signature = ''
    for _, b in ipairs(A.buffs) do
        signature = signature .. b.name .. ':' .. (b.category or 'unknown') .. ':' .. tostring(b.skillBonus) .. ':' .. tostring(b.perceptionBonus)
    end
    local skill = A.Provider.Skill()
    signature = signature .. tostring(skill.current) .. ':' .. tostring(skill.bonus)
    if signature ~= A.lastStatusSignature then A.Debug('Fishing skill/buff changed', signature); A.lastStatusSignature = signature end
end
f:RegisterEvent('ADDON_LOADED')
f:SetScript('OnEvent', function(_, event, ...)
    if event == 'ADDON_LOADED' then
        if ... ~= addonName then return end
        if not A.Store.Init() then return end
        A.UI.Build(); A.Settings.Build(); A.Celebration.Build()
        SLASH_FISHINBUDS1 = '/fb'; SLASH_FISHINBUDS2 = '/fishinbuds'
        SlashCmdList.FISHINBUDS = A.Settings.Command
        for _, e in ipairs({'PLAYER_ENTERING_WORLD', 'PLAYER_LOGOUT', 'UNIT_SPELLCAST_CHANNEL_START', 'UNIT_SPELLCAST_SUCCEEDED',
            'UNIT_SPELLCAST_CHANNEL_STOP', 'UNIT_SPELLCAST_FAILED', 'UNIT_SPELLCAST_INTERRUPTED',
            'LOOT_READY', 'LOOT_OPENED', 'LOOT_SLOT_CLEARED', 'LOOT_CLOSED', 'UNIT_AURA',
            'SKILL_LINES_CHANGED', 'PLAYER_EQUIPMENT_CHANGED', 'PROFESSION_EQUIPMENT_CHANGED', 'ZONE_CHANGED_NEW_AREA', 'ZONE_CHANGED',
            'SPELLS_CHANGED', 'SPELL_DATA_LOAD_RESULT', 'CRITERIA_UPDATE'}) do
            local ok = pcall(f.RegisterEvent, f, e)
            if not ok then A.Debug('Event unavailable', e) end
        end
        local tick, poll = 0, 0
        f:SetScript('OnUpdate', function(_, elapsed)
            tick, poll = tick + elapsed, poll + elapsed
            if tick < 1 then return end
            tick = 0
            A.Session.Tick(); A.Celebration.Tick()
            if poll >= 5 then
                poll = 0
                if A.char.current or A.UI.frame:IsShown() then A.RefreshBuffs() end
            end
            if A.UI.frame:IsShown() then
                A.UI.UpdateStatus()
                if A.UI.tab == 'Me' then A.UI.Render() end
            end
        end)
        A.RefreshBuffs(); A.QueueJournal()
        A.Print('Communicator ready. Cast Fishing, or use /fb. Settings: /fb settings')
        return
    end
    if not A.char then return end
    local arg1, arg2, arg3 = ...
    if event:find('UNIT_SPELLCAST', 1, true) == 1 then
        if arg1 ~= 'player' or not A.Provider.IsFishing(arg3) then return end
        A.Debug('Fishing event', event, arg3)
        if event == 'UNIT_SPELLCAST_CHANNEL_START' or event == 'UNIT_SPELLCAST_SUCCEEDED' then
            A.Session.Start(arg2)
        else A.Session.casting = false end
    elseif event == 'LOOT_READY' or event == 'LOOT_OPENED' then
        A.Session.ScanLoot()
        if next(A.Session.loot) then A.Debug('Fishing event', event); A.Session.casting = false end
    elseif event == 'LOOT_SLOT_CLEARED' then A.Session.ClearSlot(arg1)
    elseif event == 'LOOT_CLOSED' then A.Session.loot = {}
    elseif event == 'PLAYER_LOGOUT' then
        -- Keep the last genuine activity timestamp; never extend a session at logout.
        A.Debug('Session saved')
    elseif event == 'UNIT_AURA' then
        if arg1 == 'player' and (A.char.current or A.UI.frame:IsShown()) then A.RefreshBuffs(); A.Refresh() end
    elseif event == 'SPELL_DATA_LOAD_RESULT' then
        if A.Provider.spells[arg1] and arg2 then A.QueueJournal() end
    elseif event == 'CRITERIA_UPDATE' or event == 'SPELLS_CHANGED' then A.QueueJournal()
    else A.RefreshBuffs(); A.QueueJournal(); A.Refresh() end
end)

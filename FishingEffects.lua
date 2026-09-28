local _, A = ...
local E = {}
A.Effects = E
E.labels = { lure = 'Fishing lure', skill = 'Fishing skill bonus', perception = 'Perception consumable', tea = 'Relaxed Tea',
    bait = 'Bait', equipment = 'Fishing equipment', cosmetic = 'Bobber / appearance',
    other = 'Fishing effect', unknown = 'Unidentified fishing effect' }
-- Recognition never supplies a magnitude. Values come only from readable live
-- aura/tool tooltips, not static spell descriptions or assumed item quality.
E.known = {
    [1269152] = 'tea',        -- Relaxed: Sanguithorn Tea's Perception variant
    [1236763] = 'perception', -- Haranir Phial of Perception
    [432265] = 'perception',  -- Phial of Truesight
    [393714] = 'perception',  -- Crystalline Phial of Perception
    [394009] = 'cosmetic',   -- Fishing For Attention (equipment appearance)
    [1303610] = 'cosmetic',  -- Retail 12.1 equipment appearance variant
}
E.names = {
    ['haranir phial of perception'] = 'perception',
    ['crystalline phial of perception'] = 'perception',
    ['phial of truesight'] = 'perception',
    ['fishing for attention'] = 'cosmetic',
    ['oversized bobbers'] = 'cosmetic',
}
function E.Clean(text)
    return (text:gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', ''))
end
function E.TooltipText(data)
    local lines = {}
    for _, line in ipairs(data and A.Public(data.lines) and data.lines or {}) do
        if A.Public(line) then
            for _, field in ipairs({'leftText', 'rightText'}) do
                local value = A.Text(line[field])
                if value then lines[#lines + 1] = E.Clean(value) end
            end
        end
    end
    return table.concat(lines, '\n')
end
function E.English() local locale = GetLocale(); return locale == 'enUS' or locale == 'enGB' end
function E.Stat(text, stat)
    if not E.English() or not A.Text(text) then return nil end
    text = E.Clean(text):lower()
    local key = stat == 'fishing' and 'fishing skill' or 'perception'
    local patterns = { key .. ' increased by (%d+)(.*)',
        'increases your ' .. key .. ' by (%d+)(.*)',
        'increases ' .. key .. ' by (%d+)(.*)',
        '%+(%d+)(%s+' .. key .. ')' }
    if stat == 'fishing' then patterns[#patterns + 1] = '%+(%d+)(%s+fishing)' end
    for _, pattern in ipairs(patterns) do
        local value, tail = text:match(pattern)
        if value and not tail:match('^%s*%%') and not tail:match('^[.,]%d') then return tonumber(value) end
    end
end
function E.Classify(name, id, description, liveText, keyword)
    local lower = name:lower()
    local text = (lower .. '\n' .. (description or '') .. '\n' .. (liveText or '')):lower()
    local category = E.known[id] or (E.English() and E.names[lower])
    local fishing = text:find(keyword:lower(), 1, true)
    -- Other teas share the name Relaxed. Only recognize an unknown variant as
    -- fishing tea when its live tooltip explicitly identifies Perception.
    if not category and E.English() and lower == 'relaxed' and E.Stat(liveText, 'perception') then category = 'tea' end
    if not category and E.English() then
        if lower:find('bobber', 1, true) then category = 'cosmetic'
        elseif lower:find('bait', 1, true) and fishing then category = 'bait'
        elseif lower:find('lure', 1, true) and fishing then category = 'lure'
        elseif text:find('perception', 1, true) and
            (fishing or lower:find('phial', 1, true) or lower:find('flask', 1, true)) then category = 'perception'
        elseif E.Stat(liveText, 'fishing') then category = 'skill'
        elseif fishing and (text:find('walk on water', 1, true) or text:find('swim', 1, true)) then category = 'other' end
    end
    if not category and fishing then category = 'unknown' end
    if not category then return nil end
    return category
end
function E.Timer(effect)
    if effect.expires and effect.expires > 0 then
        local remaining = math.max(0, effect.expires - GetTime())
        return remaining == 0 and 'Expired' or A.Duration(remaining), remaining
    end
    return effect.timerText or 'Time unknown'
end
function E.BonusText(effect)
    local parts = {}
    if effect.skillBonus ~= nil then parts[#parts + 1] = '+' .. effect.skillBonus .. ' Fishing' end
    if effect.perceptionBonus ~= nil then parts[#parts + 1] = '+' .. effect.perceptionBonus .. ' Perception' end
    return table.concat(parts, ' / ')
end
function E.Select(category)
    local first, count
    count = 0
    for _, effect in ipairs(A.buffs or {}) do
        if effect.category == category and (not effect.expires or effect.expires == 0 or effect.expires > GetTime()) then
            count = count + 1
            local expiry = effect.expires and effect.expires > 0 and effect.expires or math.huge
            local firstExpiry = first and first.expires and first.expires > 0 and first.expires or math.huge
            if not first or expiry < firstExpiry then first = effect end
        end
    end
    return first, count
end

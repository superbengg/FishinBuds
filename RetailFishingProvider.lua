local _, A = ...
local P = { id = 'retail-journal-v1', spells = {}, fishingSpells = { [7620] = true, [131474] = true, [131476] = true } }
A.Provider = P
-- Retail 12.1 journal spell identifiers, corroborated by BrinyBest's catalog.
-- Data identifiers only; no third-party implementation is embedded here.
-- Dynamic profession discovery below can add future entries. Unsupported IDs
-- are harmless: absent/unreadable descriptions never become score records.
for _, id in ipairs({1225245, 1225266, 1225267, 1225268, 1225269, 1225270,
    1225271, 1225272, 1225273, 1225274, 1225275, 1225276, 1225277, 1225278,
    1225279, 1225280, 1225281, 1225282, 1225283, 1225284, 1295404, 1295405,
    1295406, 1295407, 1295408, 1295409, 1295410, 1295411}) do P.spells[id] = true end
P.requested = {}
function P.IsFishing(spellID)
    if not A.Number(spellID) then return false end
    if P.fishingSpells[spellID] then return true end
    local info = A.Safe(C_Spell and C_Spell.GetSpellInfo, spellID)
    local base = A.Safe(C_Spell and C_Spell.GetSpellInfo, 131474)
    return info and base and A.Text(info.name) and info.name == A.Text(base.name) or false
end
function P.Skill()
    local info = A.Safe(C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID, 356)
    if info and A.Number(info.skillLevel) and A.Number(info.maxSkillLevel) and info.maxSkillLevel > 0 then
        return { current = info.skillLevel, maximum = info.maxSkillLevel,
            bonus = A.Number(info.skillModifier), name = A.Text(info.professionName) or 'Fishing', source = 'Fishing profession' }
    end
    if GetProfessions and GetProfessionInfo then
        local ok, _, _, _, fishing = pcall(GetProfessions)
        if ok and fishing then
            local success, name, _, rank, maxRank, _, _, _, modifier = pcall(GetProfessionInfo, fishing)
            if success then return { current = A.Number(rank), maximum = A.Number(maxRank), bonus = A.Number(modifier), name = A.Text(name) or 'Fishing', source = 'Fishing profession' } end
        end
    end
    return { name = 'Fishing', source = 'Skill unavailable' }
end
function P.ToolSlots()
    return A.Safe(C_TradeSkillUI and C_TradeSkillUI.GetProfessionSlots, Enum and Enum.Profession and Enum.Profession.Fishing) or {}
end
local function clean(text)
    return (text:gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', ''))
end
function P.Buffs()
    local buffs, skill = {}, P.Skill()
    local E = A.Effects
    local keyword = (skill.name or 'Fishing'):lower()
    local auraAPI = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
    for i = 1, 255 do
        local aura = A.Safe(auraAPI, 'player', i, 'HELPFUL')
        if not aura then break end
        local name, id = A.Text(aura.name), A.Number(aura.spellId)
        local description = id and A.Safe(C_Spell and C_Spell.GetSpellDescription, id)
        local liveText = E.TooltipText(A.Safe(C_TooltipInfo and C_TooltipInfo.GetUnitAura, 'player', i, 'HELPFUL'))
        local category = name and E.Classify(name, id, A.Text(description), liveText, keyword)
        if category then
            local effect = { name = name, spellID = id, category = category, expires = A.Number(aura.expirationTime),
                source = 'active-aura', evidence = liveText ~= '' and 'active-aura-tooltip' or 'identity-only' }
            if category ~= 'cosmetic' and category ~= 'unknown' then
                effect.skillBonus = E.Stat(liveText, 'fishing')
                effect.perceptionBonus = E.Stat(liveText, 'perception')
            end
            buffs[#buffs + 1] = effect
        end
    end
    -- Retail's slot-based enchant API also supports profession equipment.
    -- The enchant ID is not a spell ID; do not look it up as one.
    for _, slot in ipairs(P.ToolSlots()) do
        local enchant = A.Safe(C_PaperDollInfo and C_PaperDollInfo.GetTemporaryEnchantmentInfo, slot)
        local enchantBuff
        if enchant then
            local remaining = A.Number(enchant.remainingTimeMs)
            local hasTime = A.Public(enchant.hasExpirationTime) and enchant.hasExpirationTime
            enchantBuff = { name = 'Fishing tool effect', source = 'temporary-tool-enchant', category = 'unknown',
                enchantID = A.Number(enchant.enchantID), priority = 1,
                expires = hasTime and remaining and (GetTime() + remaining / 1000) or nil }
            buffs[#buffs + 1] = enchantBuff
        end
        local data = A.Safe(C_TooltipInfo and C_TooltipInfo.GetInventoryItem, 'player', slot)
        for _, line in ipairs(data and A.Public(data.lines) and data.lines or {}) do
            local text = A.Public(line) and A.Text(line.leftText)
            if text then
                text = clean(text)
                local lower = text:lower()
                local relevant = lower:find(keyword, 1, true) or lower:find('lure', 1, true) or lower:find('bait', 1, true)
                local minutes = text:match('%((%d+) min[^%)]*%)')
                local seconds = text:match('%((%d+) sec[^%)]*%)')
                if relevant and (minutes or seconds) then
                    if not enchantBuff then
                        enchantBuff = { source = 'tool-tooltip', tooltip = true, priority = 1 }
                        buffs[#buffs + 1] = enchantBuff
                    end
                    enchantBuff.name = text:gsub('%(%d+ [ms][ie][nc][^%)]*%)', '')
                    enchantBuff.category = E.Classify(enchantBuff.name, nil, '', text, keyword) or 'unknown'
                    enchantBuff.skillBonus = E.Stat(text, 'fishing')
                    enchantBuff.perceptionBonus = E.Stat(text, 'perception')
                    -- A timed Fishing skill enchant is a lure even if named Fish Attractor.
                    if enchantBuff.skillBonus then enchantBuff.category = 'lure' end
                    enchantBuff.timerText = minutes and ('~' .. minutes .. ' min') or ('~' .. seconds .. ' sec')
                    enchantBuff.evidence = 'equipped-tool-tooltip'
                end
            end
        end
        -- Equipment contributions are separate from active consumables. Exclude
        -- use effects and timed enchant lines; do not add these to the API total.
        local permanent = {}
        for _, line in ipairs(data and A.Public(data.lines) and data.lines or {}) do
            local text = A.Public(line) and A.Text(line.leftText)
            if text and not text:find('%(%d+ ') and not text:lower():find('use:', 1, true) then
                permanent[#permanent + 1] = text
            end
        end
        local text = table.concat(permanent, '\n')
        local bonus, perception = E.Stat(text, 'fishing'), E.Stat(text, 'perception')
        if bonus or perception then
            buffs[#buffs + 1] = { name = 'Fishing gear', category = 'equipment', slot = slot,
                skillBonus = bonus, perceptionBonus = perception, source = 'equipped-item-tooltip', evidence = 'equipped-item-tooltip' }
        end
    end
    table.sort(buffs, function(a, b)
        if (a.priority or 2) ~= (b.priority or 2) then return (a.priority or 2) < (b.priority or 2) end
        return (a.expires or math.huge) < (b.expires or math.huge)
    end)
    return buffs
end
function P.ParseScore(description, locale)
    if locale ~= 'enUS' and locale ~= 'enGB' then return nil end
    if not A.Text(description) then return nil end
    local text = clean(description)
    local score = tonumber(text:match("Anglin' Score:%s*([%d]+%.?%d*)"))
    if not score or score < 0 or score > 100 then return nil end
    local rank = text:match('Catch Rank:%s*([%a]+)')
    return score, rank
end
function P.ReadJournal()
    local profession = Enum and Enum.Profession and Enum.Profession.Fishing
    local ids = profession and A.Safe(C_TradeSkillUI and C_TradeSkillUI.GetProfessionSpells, profession)
    for _, id in ipairs(ids or {}) do P.spells[id] = true end
    local count = 0
    for id in pairs(P.spells) do
        local description = A.Safe(C_Spell and C_Spell.GetSpellDescription, id)
        local value, rank = P.ParseScore(description, GetLocale())
        if value then
            local info = A.Safe(C_Spell and C_Spell.GetSpellInfo, id)
            local zone, subzone = A.Location()
            A.Store.Journal({ provider = P.id, speciesID = id, name = info and A.Text(info.name) or 'Unidentified journal fish',
                score = { system = 'anglin-journal-best', value = value, unit = 'points', scope = 'journal', higherIsBetter = true },
                rank = rank, trophy = rank == 'Trophy' and value == 100,
                timestamp = time(), zone = zone, subzone = subzone, character = A.char.name,
                skill = P.Skill(), evidence = 'journal-description', kind = 'journal-observation' })
            count = count + 1
        elseif not description and not P.requested[id] then
            P.requested[id] = true
            A.Safe(C_Spell and C_Spell.RequestLoadSpellData, id)
        end
    end
    P.journalCount = count
end
function P.Interpret(raw)
    -- Quality is loot rarity, not Trophy rank. No per-catch score is invented.
    return { provider = P.id, kind = 'catch', itemID = raw.itemID, link = raw.link,
        quantity = raw.quantity, quality = raw.quality, timestamp = raw.timestamp,
        zone = raw.zone, subzone = raw.subzone, character = A.char.name,
        skill = raw.skill, evidence = 'fishing-loot-slot-cleared' }
end

local _, A = ...
A.Session = { loot = {}, casting = false }
local S = A.Session
function S.Start(guid)
    if guid and guid == S.lastCast then return end
    S.lastCast = guid
    local now = time()
    if A.char.current and now - A.char.current.lastActivity > A.db.settings.idleSeconds then S.Stop() end
    if not A.char.current then
        A.char.current = { id = A.Store.ID(), started = now, lastActivity = now, casts = 0, catches = 0, items = 0 }
        A.Debug('Fishing started')
    end
    local s = A.char.current
    s.casts, s.lastActivity = s.casts + 1, now
    A.char.stats.casts = A.char.stats.casts + 1
    S.casting = true
    if A.db.settings.autoShow and not A.UI.frame:IsShown() then A.UI.Show('Feed', true) end
    if A.db.settings.feedOnCast and A.UI.frame:IsShown() then A.UI.SelectTab('Feed') end
    A.Refresh()
end
function S.Stop()
    A.Store.EndSession()
    S.casting, S.lastCast = false, nil
    A.Debug('Fishing stopped (idle)')
    if A.db.settings.autoHide and A.UI.autoOpened then A.UI.frame:Hide() end
    A.Refresh()
end
function S.ScanLoot()
    if not A.Safe(IsFishingLoot) then return end
    -- A fishing loot source remains authoritative even if the cast event was missed.
    if not A.char.current then
        local now = time()
        A.char.current = { id = A.Store.ID(), started = now, lastActivity = now, casts = 0, catches = 0, items = 0 }
    end
    for slot = 1, (A.Safe(GetNumLootItems) or 0) do
        if not S.loot[slot] then
            local link = A.Safe(GetLootSlotLink, slot)
            if link then
                local ok, _, _, quantity, _, quality = pcall(GetLootSlotInfo, slot)
                local zone, subzone = A.Location()
                if ok and A.Number(quantity) and quantity > 0 then
                    S.loot[slot] = { link = link, itemID = tonumber(link:match('item:(%d+)')),
                        quantity = quantity, quality = A.Number(quality), timestamp = time(),
                        zone = zone, subzone = subzone, skill = A.Provider.Skill() }
                end
            end
        end
    end
end
function S.ClearSlot(slot)
    local raw = S.loot[slot]
    if not raw or raw.confirmed then return end
    raw.confirmed = true
    raw.timestamp = time()
    A.Store.Catch(A.Provider.Interpret(raw))
    A.QueueJournal()
end
function S.Tick()
    if A.char.current and time() - A.char.current.lastActivity > A.db.settings.idleSeconds then S.Stop() end
end

local _, A = ...
A.Store = {}
local defaults = { autoShow = true, autoHide = true, idleSeconds = 90, debug = false, celebrations = true,
    feedOnCast = false, warningSeconds = 60 }
function A.Store.Init()
    if type(FishinBudsDB) ~= 'table' then FishinBudsDB = {} end
    local db = FishinBudsDB
    if db.schema and db.schema > 1 then
        A.Print('Your fishing notebook needs a newer version of Fishin\' Buds. Update the addon to open it safely.')
        return false
    end
    db.schema = 1
    db.settings = type(db.settings) == 'table' and db.settings or {}
    for k, v in pairs(defaults) do
        if type(db.settings[k]) ~= type(v) then db.settings[k] = v end
    end
    db.settings.idleSeconds = math.max(30, math.min(600, db.settings.idleSeconds))
    db.settings.warningSeconds = math.max(15, math.min(300, db.settings.warningSeconds))
    db.characters = type(db.characters) == 'table' and db.characters or {}
    A.db = db
    local key = UnitGUID('player') or ((UnitName('player') or 'Player') .. '-' .. (GetRealmName() or 'Realm'))
    local c = db.characters[key] or {}
    db.characters[key], A.char = c, c
    c.name = (UnitName('player') or 'Player') .. '-' .. (GetRealmName() or '')
    for _, k in ipairs({'recent', 'feed', 'sessions', 'best', 'journal', 'trophies'}) do
        if type(c[k]) ~= 'table' then c[k] = {} end
    end
    c.stats = c.stats or { casts = 0, catches = 0, items = 0, rare = 0, seconds = 0 }
    c.nextID = c.nextID or 0
    -- Resume within the idle window; longer offline gaps are not counted.
    if c.current and time() - c.current.lastActivity > db.settings.idleSeconds then
        A.Store.EndSession()
    end
    A.Trim(c.recent, 200); A.Trim(c.feed, 100); A.Trim(c.sessions, 30); A.Trim(c.trophies, 100)
    return true
end
function A.Store.ID()
    A.char.nextID = A.char.nextID + 1
    return tostring(A.char.nextID)
end
function A.Store.EndSession()
    local s = A.char.current
    if not s then return end
    s.ended = s.lastActivity
    table.insert(A.char.sessions, 1, s); A.Trim(A.char.sessions, 30)
    A.char.stats.seconds = A.char.stats.seconds + math.max(0, s.lastActivity - s.started)
    A.char.current = nil
end
function A.Store.Catch(c)
    c.id = A.Store.ID()
    table.insert(A.char.recent, 1, c); A.Trim(A.char.recent, 200)
    local stats, s = A.char.stats, A.char.current
    stats.catches, stats.items = stats.catches + 1, stats.items + c.quantity
    if c.quality and c.quality >= 3 then stats.rare = stats.rare + 1 end
    if s then s.catches = s.catches + 1; s.items = s.items + c.quantity; s.lastActivity = c.timestamp end
    A.Debug('Catch detected', c.itemID, c.link, 'quantity', c.quantity, 'quality', c.quality)
    A.Emit('CATCH', c)
    A.Refresh()
end
function A.Store.Journal(observation)
    local key = observation.provider .. ':' .. observation.speciesID
    local old = A.char.journal[key]
    -- Delayed/stale description data must not lower a best and then recreate it.
    if old and observation.score.value <= old.score.value then return end
    A.char.journal[key] = observation
    -- Initial discovery is a baseline, never a new catch or a celebration.
    if old and observation.score.value > old.score.value then
        A.char.best[key] = observation
        if observation.trophy then
            table.insert(A.char.trophies, 1, observation); A.Trim(A.char.trophies, 100)
        end
        A.Debug('Personal record detected (journal observation)', observation.name, old.score.value, '->', observation.score.value)
        A.Emit('RECORD', observation, old)
    end
end

emit('ADDON_LOADED', 'Unrelated')
assert(not A.db)
emit('ADDON_LOADED', 'FishinBuds')
assert(A.db.schema == 1 and not A.UI.frame:IsShown())
advance(4)
assert(A.Provider.journalCount == 1 and #A.char.feed == 0, 'baseline must not celebrate')
assert(#A.buffs == 1)
assert(A.Provider.Skill().bonus == 15)
C_PaperDollInfo = {GetTemporaryEnchantmentInfo = function(slot)
    assert(slot == 28)
    return {enchantID=100, remainingTimeMs=120000, hasExpirationTime=true}
end}
local toolBuffs = A.Provider.Buffs()
assert(toolBuffs[1].priority == 1 and toolBuffs[1].expires == clock + 120)
C_PaperDollInfo.GetTemporaryEnchantmentInfo = function() return {remainingTimeMs={secret=true}, hasExpirationTime={secret=true}} end
assert(A.Provider.Buffs()[1].expires == nil)
C_PaperDollInfo = nil
C_TooltipInfo.GetInventoryItem = function() return {lines={{leftText='Fishing Lure (+100 Fishing) (9 min remaining)'}}} end
assert(A.Provider.Buffs()[1].tooltip == true)
C_TooltipInfo.GetInventoryItem = function() return {lines={}} end
assert(not A.Public({secret=true}) and A.Text({secret=true}) == nil)
assert(A.Provider.ParseScore("Anglin' Score: 99.9", 'deDE') == nil)
assert(A.Provider.ParseScore("Anglin' Score: 101", 'enUS') == nil)

emit('UNIT_SPELLCAST_SUCCEEDED', 'player', 'cast-1', 131474)
emit('UNIT_SPELLCAST_CHANNEL_START', 'player', 'cast-1', 131474)
assert(A.char.stats.casts == 1 and A.char.current.casts == 1, 'deduplicate cast events')
assert(A.UI.frame:IsShown() and A.UI.tab == 'Feed')
A.UI.tab = 'Me'
emit('UNIT_SPELLCAST_CHANNEL_START', 'player', 'cast-2', 131474)
assert(A.UI.tab == 'Me', 'recasts must not interrupt browsing')
A.db.settings.feedOnCast = true
A.UI.SelectTab('Me')
emit('UNIT_SPELLCAST_CHANNEL_START', 'player', 'cast-feed', 131474)
assert(A.UI.tab == 'Feed', 'optional Feed selection on recasts')
A.db.settings.feedOnCast = false
emit('LOOT_READY'); emit('LOOT_OPENED')
assert(A.char.stats.catches == 0, 'uncollected loot must not count')
emit('LOOT_SLOT_CLEARED', 1); emit('LOOT_SLOT_CLEARED', 1)
assert(A.char.stats.catches == 1 and A.char.stats.items == 2)
assert(#A.char.recent == 1 and #A.char.feed == 1 and A.char.recent[1].score == nil)
emit('LOOT_CLOSED')
fishingLoot = false
emit('LOOT_READY'); emit('LOOT_SLOT_CLEARED', 1)
assert(A.char.stats.catches == 1, 'ordinary loot must not count')
fishingLoot = true

score, rank = 100, 'Trophy'
advance(4)
assert(#A.char.trophies == 1 and #A.char.feed == 2)
A.Provider.ReadJournal()
assert(#A.char.trophies == 1, 'repeated scores must not celebrate twice')
score = 50; A.Provider.ReadJournal(); score = 100; A.Provider.ReadJournal()
assert(#A.char.trophies == 1, 'stale journal data must not fabricate new improvements')
advance(6)
assert(A.Celebration.frame.title.text == 'NOW THAT is a nice fish.')
for _, tab in ipairs({'Feed','Me','Buds','Realm','Records'}) do A.UI.Show(tab); A.Refresh() end
assert(#A.UI.rows > 0)
A.Settings.Toggle()
assert(A.Settings.frame:IsShown())
A.Settings.Command('timeout 1'); assert(A.db.settings.idleSeconds == 30)
A.Settings.Command('timeout 999'); assert(A.db.settings.idleSeconds == 600)
A.Settings.Command('timeout 90')
A.Settings.Command('status')
A.UI.Show('Feed', true)
advance(91)
assert(not A.char.current and not A.UI.frame:IsShown())
A.UI.Show('Me', false)
emit('UNIT_SPELLCAST_CHANNEL_START', 'player', 'cast-3', 131474)
advance(91)
assert(A.UI.frame:IsShown(), 'manual windows stay open')
A.db.settings.autoShow = false; A.UI.frame:Hide()
emit('UNIT_SPELLCAST_CHANNEL_START', 'player', 'cast-4', 131474)
assert(not A.UI.frame:IsShown())

-- Missing APIs and restricted values produce unavailable status, no Lua errors.
C_TradeSkillUI, C_Spell, C_UnitAuras, C_TooltipInfo = nil, nil, nil, nil
assert(not A.Provider.Skill().current)
assert(#A.Provider.Buffs() == 0)
A.Provider.ReadJournal()
A.UI.Show('Me'); A.Settings.Command('status')
assert(A.Provider.IsFishing(131474) and not A.Provider.IsFishing(888))

-- Retention, independent characters, reload session handling, future schema guard.
for i = 1, 240 do
    A.Store.Catch({link='item:1', itemID=1, quantity=1, timestamp=clock, zone='Waters', subzone='', quality=1})
end
assert(#A.char.recent == 200)
assert(#A.char.feed <= 100)
local old = A.char
local oldCatches, oldFeed = A.char.stats.catches, A.char.feed
A.db.settings.autoShow = false
A.Store.Init()
assert(A.char == old and A.char.stats.catches == oldCatches and A.char.feed == oldFeed and not A.db.settings.autoShow)
function UnitGUID() return 'Player-2' end
A.Store.Init(); assert(A.char ~= old and A.char.stats.catches == 0)
function UnitGUID() return 'Player-1' end
A.Store.Init(); assert(A.char == old)
clock = clock + 1000; A.Store.Init(); assert(not A.char.current)
FishinBudsDB.schema = 99
assert(A.Store.Init() == false and FishinBudsDB.schema == 99)
print('All event, UI, scoring, persistence, retention, and fallback scenarios passed.')

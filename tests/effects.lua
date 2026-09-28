local E = A.Effects
assert(E.Stat('Fishing Lure (+20 Fishing Skill)', 'fishing') == 20)
assert(E.Stat('Fishing Lure (+100 Fishing)', 'fishing') == 100)
assert(E.Stat('Perception increased by 45 and Deftness increased by 14.', 'perception') == 45)
assert(E.Stat('Increases your Perception by 50.', 'perception') == 50)
assert(E.Stat('Perception increased by 20%', 'perception') == nil)
assert(E.Stat('Perception increased by 1,000', 'perception') == nil)
assert(E.Stat('Perception increased by 2.5', 'perception') == nil)
assert(E.Stat('Lasts 30 min. Perception helps find treasures.', 'perception') == nil)
assert(E.Classify('Fishing For Attention',394009,'Increases Fishing skill by 100.','','Fishing') == 'cosmetic')
assert(E.Classify('Oversized Bobbers',nil,'Makes the Fishing bobber bigger.','','Fishing') == 'cosmetic')
assert(E.Classify('Mysterious fishing glow',nil,'Something happens.','','Fishing') == 'unknown')
assert(E.Classify('Helpful Fishing',nil,'','Fishing skill increased by 5 for 10 minutes.','Fishing') == 'skill')
assert(E.Classify('Fish Bait',nil,'Fishing bait.','','Fishing') == 'bait')
assert(E.Classify('Water Walking',nil,'Walk on water while Fishing.','','Fishing') == 'other')
assert(E.Classify('Combat flask',nil,'Increases strength.','','Fishing') == nil)

local savedAuras, savedTooltip, savedSpell = auras, C_TooltipInfo.GetUnitAura, C_Spell.GetSpellDescription
auras = {
    {name='Fishing For Attention', spellId=394009, expirationTime=0},
    {name='Oversized Bobbers', spellId=222, expirationTime=clock+3600},
    {name='Haranir Phial of Perception', spellId=1236763, expirationTime=clock+2400},
    {name='Crystalline Phial of Perception', spellId=393714, expirationTime=clock+900},
    {name='Fishing Lure', spellId=901, expirationTime=clock+45},
    {name='Unknown fishing effect', spellId=902, expirationTime=clock+60},
}
C_TooltipInfo.GetUnitAura = function(_, index, filter)
    assert(filter == 'HELPFUL')
    if index == 3 then return {lines={{leftText='Perception increased by 45 and Deftness increased by 14.'}}} end
    if index == 4 then return {lines={{leftText='Perception increased by 30 for 30 minutes.'}}} end
    if index == 5 then return {lines={{leftText='Fishing skill increased by 20 for 10 minutes.'}}} end
end
C_Spell.GetSpellDescription = function(id)
    if id == 901 then return 'Increases Fishing skill by 999 for 10 minutes.' end
    return savedSpell(id)
end
A.RefreshBuffs()
assert(#A.buffs == 6)
local lure = E.Select('lure')
assert(lure.skillBonus == 20, 'live aura tooltip must win over static description')
local perception, count = E.Select('perception')
assert(count == 2 and perception.spellID == 393714 and perception.perceptionBonus == 30)
A.UI.Show('Me')
assert(A.UI.readouts.lure.heading.text:find('Expiring', 1, true))
assert(A.UI.readouts.perception.name.text:find('+1 more', 1, true))
assert(not A.UI.readouts.lure.name.text:find('Attention', 1, true))
C_TooltipInfo.GetUnitAura = function() return {lines={{leftText={secret=true}}}} end
A.RefreshBuffs()
assert(E.Select('lure').skillBonus == nil, 'static descriptions must not supply numeric bonuses')
assert(E.Select('perception').perceptionBonus == nil)
local oldLocale = GetLocale
function GetLocale() return 'deDE' end
A.RefreshBuffs()
assert(E.Select('perception'), 'known spell IDs work across locales')
assert(E.Stat('Perception increased by 30 for 10 minutes.', 'perception') == nil)
GetLocale = oldLocale
auras = {savedAuras[1]}
auras[1] = {name='Fishing For Attention', spellId=394009, expirationTime=0}
A.RefreshBuffs(); A.UI.UpdateStatus()
assert(not E.Select('lure'))
assert(A.UI.readouts.lure.heading.text:find('None detected', 1, true))
auras, C_TooltipInfo.GetUnitAura, C_Spell.GetSpellDescription = savedAuras, savedTooltip, savedSpell
A.UI.frame:Hide(); A.RefreshBuffs()

-- Old posts receive friendlier display without mutating their saved contents.
local post = {kind='journal-best',title='Journal best improved',body='Fish\nJournal observation; individual catch score unavailable.'}
local title, body = A.Feed.Display(post)
assert(title == 'New journal best' and not body:find('individual catch score'))
assert(post.title == 'Journal best improved')
print('Classification, live values, Perception, cosmetic exclusion, warning, and legacy feed tests passed.')

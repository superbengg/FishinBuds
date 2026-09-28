local E = A.Effects
local original, tooltip = auras, C_TooltipInfo.GetUnitAura
auras = {
    {name='Fishing Lure',spellId=901,expirationTime=clock+600},
    {name='Haranir Phial of Perception',spellId=1236763,expirationTime=clock+1800},
    {name='Relaxed',spellId=1269152,expirationTime=clock+45},
}
C_TooltipInfo.GetUnitAura = function(_, i)
    local text = ({'Fishing skill increased by 20.', 'Perception increased by 45.', 'Perception increased by 27.\nSpeed increased by 80.'})[i]
    return {lines={{leftText=text}}}
end
A.RefreshBuffs(); A.UI.Show('Feed')
assert(E.Select('tea').perceptionBonus == 27)
assert(E.Select('tea').expires == clock+45)
assert(E.Select('lure').skillBonus == 20 and E.Select('perception').perceptionBonus == 45)
assert(A.UI.readouts.tea.heading.text:find('+27 Perception',1,true))
assert(A.UI.readouts.tea.heading.text:find('Expiring',1,true))
assert(E.Classify('Relaxed',nil,'','Finesse increased by 50.','Fishing') == nil)
assert(E.Classify('Relaxed',nil,'','Perception increased by 30.','Fishing') == 'tea')
C_TooltipInfo.GetUnitAura = function() return {lines={{leftText={secret=true}}}} end
A.RefreshBuffs(); assert(E.Select('tea') and E.Select('tea').perceptionBonus == nil)
local locale = GetLocale
function GetLocale() return 'deDE' end
A.RefreshBuffs(); assert(E.Select('tea') and not E.Select('tea').perceptionBonus)
GetLocale = locale
auras[3].expirationTime = clock-1
A.RefreshBuffs(); assert(not E.Select('tea'))
auras[3] = nil
A.RefreshBuffs(); A.UI.UpdateStatus()
assert(not E.Select('tea') and E.Select('perception') and E.Select('lure'))
assert(A.UI.readouts.tea.heading.text:find('None detected',1,true))
auras, C_TooltipInfo.GetUnitAura = original, tooltip
A.UI.frame:Hide(); A.RefreshBuffs()
print('Relaxed Tea isolation, live-value, localization, expiry and removal checks passed.')

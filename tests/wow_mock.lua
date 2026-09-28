-- Deliberately explicit frame API: unknown methods fail instead of disappearing.
local methods = {}
local function noop() end
for _, name in ipairs({'SetSize','SetWidth','SetHeight','SetPoint','ClearAllPoints','SetBackdrop','SetBackdropColor',
    'SetBackdropBorderColor','SetJustifyH','SetWordWrap','SetFrameStrata','SetClampedToScreen','SetMovable',
    'EnableMouse','RegisterForDrag','StartMoving','StopMovingOrSizing','SetTexture','SetScrollChild',
    'SetVerticalScroll','SetEnabled','SetAutoFocus','SetNumeric','SetMaxLetters','ClearFocus',
    'SetColorTexture','SetMaxLines'}) do methods[name] = noop end
function methods:SetText(text) self.text = text end
function methods:GetText() return self.text end
function methods:GetStringHeight() return 28 end
function methods:GetLeft() return 700 end
function methods:GetBottom() return 100 end
function methods:SetChecked(value) self.checked = value end
function methods:GetChecked() return self.checked end
function methods:SetScript(event, fn) self.scripts[event] = fn end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:IsShown() return self.shown end
function methods:SetShown(value) self.shown = value end
function CreateFrame() return setmetatable({shown = true, scripts = {}, events = {}}, {__index = methods}) end
function methods:CreateTexture() return CreateFrame() end
function methods:CreateFontString() return CreateFrame() end
UIParent = CreateFrame()
SlashCmdList = {}
GameTooltip = {SetOwner=noop, SetInventoryItem=noop, AddLine=noop, Show=noop, Hide=noop, SetHyperlink=noop}
clock = 1000
function time() return clock end
function GetTime() return clock end
date = os.date
function UnitGUID() return 'Player-1' end
function UnitName() return 'Test Angler' end
function GetRealmName() return 'Test Realm' end
function GetZoneText() return 'Test Waters' end
function GetSubZoneText() return 'Test Shore' end
function GetLocale() return 'enUS' end
function InCombatLockdown() return false end
function issecretvalue(v) return type(v) == 'table' and v.secret == true end
Enum = {Profession = {Fishing = 9}}
timers = {}
C_Timer = {After = function(delay, fn) table.insert(timers, {at = clock + delay, fn = fn}) end}
function advance(seconds)
    clock = clock + seconds
    local pending = timers; timers = {}
    for _, entry in ipairs(pending) do if entry.at <= clock then entry.fn() else table.insert(timers, entry) end end
    if A.events.scripts.OnUpdate then A.events.scripts.OnUpdate(A.events, seconds) end
end
score, rank = 50, 'Pike'
C_Spell = {
    GetSpellInfo = function(id) return {name = id == 1225245 and 'Test Fish' or 'Fishing'} end,
    GetSpellDescription = function(id)
        if id == 1225245 then return "Anglin' Score: " .. score .. ' points\nCatch Rank: ' .. rank end
        if id == 900 then return 'Increases Fishing skill.' end
    end,
    RequestLoadSpellData = noop,
}
C_TradeSkillUI = {
    GetProfessionInfoBySkillLineID = function() return {skillLevel=100, maxSkillLevel=100, skillModifier=15, professionName='Fishing'} end,
    GetProfessionSlots = function() return {28} end,
    GetProfessionSpells = function() return {1225245} end,
}
auras = {{name='Test fishing lure', spellId=900, expirationTime=1600}}
C_UnitAuras = {GetAuraDataByIndex = function(_, i) return auras[i] end}
C_TooltipInfo = {GetInventoryItem=function() return {lines={}} end}
fishingLoot = true
loot = {{link='|cff0070dd|Hitem:123:0|h[Test Fish]|h|r', quantity=2, quality=3}}
function IsFishingLoot() return fishingLoot end
function GetNumLootItems() return #loot end
function GetLootSlotLink(slot) return loot[slot].link end
function GetLootSlotInfo(slot) return 1, 'Test Fish', loot[slot].quantity, nil, loot[slot].quality end
function emit(event, ...) A.events.scripts.OnEvent(A.events, event, ...) end

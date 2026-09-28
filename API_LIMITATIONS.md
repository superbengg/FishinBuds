# Retail API research and assumptions

## v0.2.1: Relaxed Tea

[Sanguithorn Tea (item 242299)](https://www.wowhead.com/item=242299/sanguithorn-tea)
grants the Perception variant of [Relaxed (spell 1269152)](https://www.wowhead.com/spell=1269152/relaxed).
Its own `tea` category uses the existing live aura-tooltip parser and aura expiry
API. External pages' scaled amounts and nominal duration are never hardcoded.
Only readable Perception is shown numerically; no fishing success rate, stacking
total, or Speed amount is inferred. Removal by the game clears the reading.

Other teas share the name Relaxed. An unknown English Relaxed aura is recognized
only when its live tooltip explicitly exposes a Perception amount. Finesse and
Deftness variants are not treated as fishing Perception. Known-ID recognition
works across locales; numbers retain the existing English parsing limitation.
Missing/secret tooltip data yields a known name and readable timer without a
fabricated amount. Tea never occupies the lure or phial readouts.

Researched September 28, 2026. Installed Retail build metadata reports
12.1.0.69933; the addon declares interface 120100. Online `live` source can move
independently of an installed client, so optional APIs are capability-checked.

## Verified interfaces used

- Blizzard's [PaperDollInfo definitions](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/PaperDollInfoDocumentation.lua)
  expose `C_PaperDollInfo.GetTemporaryEnchantmentInfo(slot)` returning
  `enchantID`, `remainingTimeMs`, `chargesRemaining`, and `hasExpirationTime`.
  This supplies exact readable countdowns for temporary fishing-tool enchants.
  The addon never calls the corresponding cancellation API.
- [TradeSkillUI](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/TradeSkillUIDocumentation.lua)
  and [its types](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/TradeSkillUITypesDocumentation.lua)
  define profession information, profession slots, and known profession spells.
  The provider requests Fishing skill line 356 and `Enum.Profession.Fishing`.
  `GetProfessions` / `GetProfessionInfo` are the legacy fallback.
- [TooltipInfo](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/TooltipInfoDocumentation.lua)
  supports inspecting an equipped item by unit and inventory slot. Readable
  timed fishing/lure/bait tooltip lines are a fallback, displayed verbatim;
  rounded tooltip minutes are never passed off as a precise countdown.
- [Spell API](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua)
  exposes descriptions and asynchronous spell-data requests. The addon reads
  English Anglin' Score and Catch Rank labels from those descriptions.
- [Loot event definitions](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/LootDocumentation.lua)
  and [Blizzard's LootFrame](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/LootFrame.lua)
  establish the loot events, `IsFishingLoot`, and slot metadata used here.
- [BrinyBest's source](https://github.com/nerolabs/BrinyBest) corroborates the
  Retail journal description mechanism and the 28 fallback journal spell IDs.
  Only factual IDs are included; its implementation and artwork are not copied.

## What is and is not knowable here

1. **No dedicated per-catch Trophy/Anglin' event or structured per-catch score
   API was found in the inspected Retail generated API directory.** No
   `C_Fishing` API is invented. The journal's descriptions expose best/rank
   information, not a reliable numeric score for every looted fish.
2. **Journal observations are not catch measurements.** The journal can reflect
   warband progress, delayed updates, or progress made elsewhere. The addon
   does not attach a changed journal score to a nearby item, timestamp it as the
   original catch, or call it this character's measured fish. Observation time,
   observing character, and observing location are retained as such. Initial
   discovery is a baseline. Improvements have a separate feed kind.
3. **Trophy celebrations are conservative.** The special phrase requires both
   an explicit `Trophy` label and a value of 100, increased from a lower saved
   observation during an active local session. Ordinary rare item quality is
   never used as a Trophy score. Repeated or lower journal values are ignored.
4. **English numeric parsing.** Journal descriptions are localized and not
   a stable structured contract. enUS/enGB scoring is supported. Changed labels
   or other locales yield unavailable scoring, not zero. Ordinary catch
   tracking is locale independent. Aura matching uses the localized Fishing
   name; tooltip text fallback currently recognizes English timed lines.
5. **Lure coverage is API-dependent.** Direct equipment timers remain precise
   when readable. Enchant IDs are not spell IDs. Unknown tool enchants appear
   under Me as unidentified effects, rather than being assumed to add skill.
   Recognized lures occupy the Lure meter; cosmetics never do. Missing expiry
   reads `Time unknown`. `None detected` is not proof that every possible bait
   is absent. The native fishing-tool tooltip is available for inspection.
6. **Skill is the reported Fishing profession value.** Expansion-specific caps
   may differ. Effective skill is reported base plus reported modifier; it is
   not an independently verified total of hidden situational bonuses and does
   not predict catch success. Missing skill or modifiers remain unavailable.
7. **Only confirmed fishing loot is counted.** Each cleared item stack in a
   fishing loot source is one catch entry. Money/currency, auto-consumed results
   without a readable item slot, missed pre-addon events, and uncollected loot
   are not counted. If slot metadata is unavailable, that slot is skipped.
   Junk and non-fish fishing loot are retained. Rarity comes from slot metadata;
   missing rarity means no rarity-based celebration.
8. **Client restrictions remain in force.** Secret values are not used in
   arithmetic, parsing, or storage. Unsupported optional APIs/events fail
   gracefully. No actions apply bait, cast, loot, move, or consume items.

## Verification boundary

Offline Lua 5.1 tests verify file loading, state transitions, rendering calls
against explicit frame mocks, unavailable API fallbacks, restricted fields,
and persistence behavior. They cannot prove real client event ordering, native
frame appearance, or which journal entries the player has available. Actual
Retail v0.2 smoke testing is still required; the user already confirmed v0.1's
basic loop, status, and lure countdown. See TESTING.md.

## v0.2 effect classification

`FishingEffects.lua` holds an extensible spell-ID/name registry, categories,
and conservative stat text parsing. The provider obtains current aura tooltip
text with `C_TooltipInfo.GetUnitAura('player', index, 'HELPFUL')`, whose signature
and restricted-value rules are in the TooltipInfo definitions linked above.
Only that live text or the equipped tool tooltip supplies numeric bonuses.
Static spell descriptions help recognize an effect but never supply an amount.
Aura points are not treated as stat values because their meaning varies by spell.

Recognized Perception identities (game spell records):

- [Haranir Phial of Perception, 1236763](https://www.wowhead.com/spell=1236763/haranir-phial-of-perception)
- [Phial of Truesight, 432265](https://www.wowhead.com/spell=432265/phial-of-truesight)
- [Crystalline Phial of Perception, 393714](https://www.wowhead.com/spell=393714/crystalline-phial-of-perception)

IDs identify the active effect, never its quality or strength. The listed
numbers on external pages can differ from the player's actual scaled buff;
none are hardcoded as a bonus. Tracking a Perception phial does not assert a
particular fishing reward chance, stacking rule, or expansion applicability.

Known IDs work across languages. English name fallbacks and readable English
Fishing/Perception wording can recognize additional effects. Other languages
or changed tooltip wording may identify an effect while leaving its amount
unknown. Cosmetic exclusions include Fishing For Attention (394009/1303610)
and English bobber names. Unknown relevant effects remain in Me. Percentages,
decimal/grouped numbers, and unrelated durations are not guessed as flat stats.

Equipment lines are displayed separately and never added to the already
reported profession modifier. Tooltip contributions are not promised to be a
complete gear breakdown. Multiple matching active consumables show the soonest
readable expiry and a count; hover or Me reveals the others. Their bonuses are
not summed. Rounded tool tooltip times retain `~` and do not trigger exact
countdown warnings. Warning colors are passive; no item use is automated.

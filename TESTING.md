# Verification record and in-game smoke test

## v0.2.1 maintenance check

The user confirmed v0.2 working in Retail. Added fixtures exercise Relaxed Tea
alongside a lure and phial, separate classification, live amounts, unknown/secret
values, localization, expiry/removal, and the unchanged saved-data round trip.

After `/reload`, drink Sanguithorn Tea until Relaxed appears. Compare its new
readout with the native aura while a lure and phial are active. Check tea removal
and text fit at your normal UI scale. This new row still needs live verification.

## Offline checks completed

All ten TOC-listed Lua files load in Lua 5.1. The included harness passes:

- Fresh initialization; unrelated ADDON_LOADED ignored; silent journal baseline.
- Cast success/channel-start deduplication; recast preserves browsing tab.
- Auto/manual visibility, idle timeout, timeout clamping, settings controls.
- Fishing slot collected once despite duplicate events; no count before
  collection; non-fishing loot rejected.
- Catch item units versus stack counts, feed creation, click-through toast code.
- Exact temporary-enchant milliseconds, restricted timer fields, tooltip fallback.
- Journal improvement and Trophy detection, duplicate/regressed scores ignored.
- Five tab render paths, status command, missing API namespaces.
- History caps, independent character buckets, stale-session closure, future
  database schema preservation.

No live account data is changed by the tests. The harness mocks WoW; these are
not results of an actual in-game play session.

Version 0.2 also verifies known phials, multiple active Perception effects,
active-tooltip values instead of static descriptions, no fake bonuses from
percentages/durations, non-English ID recognition, unknown effects, cosmetic
exclusion from the lure meter, timer warnings, optional Feed selection, old
feed rendering without data mutation, and SavedVariables serialization into a
fresh Lua runtime. The working v0.1 backup remains unchanged.

## Retail smoke test still required

1. Restart Retail, enable Fishin' Buds, log into a character with Fishing. Check
   BugSack or enable `/console scriptErrors 1`. Confirm no load errors.
2. Use `/fb settings`; move/reset the communicator. Visit all five tabs, scroll
   the feed/Me/Records, hover items and the fishing tool. Check text fit at your
   normal UI scale and verify the frame does not cover your usual bobber area.
3. Cast Fishing. Confirm Feed opens; browse Me and recast. Confirm Me stays
   selected. Compare skill and modifier with the profession UI.
4. Apply your usual lure manually. Compare its timer with the equipped tool or
   aura tooltip, wait below one minute, then allow it to expire. Check an
   unsupported bait and verify the UI says unavailable instead of inventing a
   timer. Test the equipment timer if your client exposes it.
   Activate your usual Perception phial and compare its name, amount, and time.
   With only Fishing For Attention/Oversized Bobbers active, Lure must say none
   detected and those effects should appear as Bobber / appearance under Me.
   Compare the new panel and selected-tab colors at your normal UI scale.
5. Catch with autoloot on, then off. Expect one catch per collected item stack
   and the correct item-unit quantity. Leave one item uncollected; cancel a
   cast; loot an ordinary creature. These must not inflate fishing counters.
6. Confirm a first-catch feed entry. If naturally available, catch rare loot or
   improve a journal best; check feed, records, and a passive toast. An existing
   Trophy baseline must not celebrate just because the addon started.
7. Wait 90 seconds after the last activity: an auto-opened window should hide.
   Open manually and repeat: a manual window should remain. Test each automatic
   setting independently and a 30-second timeout.
   Test **Switch to Feed on every cast** both ways and configure a consumable
   warning threshold. Manual windows should still stay open after fishing.
8. `/reload`; verify retained catches, settings, and records. Switch character
   and verify separate local catch histories. Check `/fb status` and toggle
   `/fb debug` on/off. Disable script errors afterward if desired.

If a check fails, capture the full Lua error and the `/fb status` output, plus
client build, language, the lure/item name, and whether autoloot was enabled.

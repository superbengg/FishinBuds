# Architecture

## Event path

`WoW cast events -> FishingSession -> communicator visibility`

`LOOT_READY / LOOT_OPENED + IsFishingLoot -> slot snapshot`

`LOOT_SLOT_CLEARED -> RetailFishingProvider.Interpret -> CatchDatabase -> Feed -> UI / Celebration`

Loot is counted only once per confirmed fishing slot. LOOT_CLOSED releases the
snapshot. There is deliberately no chat-message parser that could count another
player's loot or double-count the loot events. A fishing loot source can start
a session even when the cast event was missed; it does not invent a cast count.

Journal reads run separately, after initialization, relevant spell/criteria
changes, and at one and three seconds after a catch. Requests are coalesced.
Missing spell descriptions receive one asynchronous load request per login.
The provider combines dynamically discovered profession spells with a small
Retail 12.1 journal-ID catalog. Unreadable descriptions produce no record.

## Modules

| File | Responsibility |
| --- | --- |
| Core.lua | Addon namespace, local event bus, public-value guards, formatting |
| CatchDatabase.lua | Schema initialization, per-character storage, retention, monotonic records |
| FishingEffects.lua | Effect registry, category labels, live-tooltip stat parser, timer selection |
| RetailFishingProvider.lua | Cast identity, skill, buffs/tool enchant timers, journal parser, catch adapter |
| FishingSession.lua | Cast deduplication, fishing loot confirmation, idle lifecycle |
| Feed.lua | Versioned local posts; reserved reactions field, no comments |
| UI.lua | Replaceable device skin, persistent status, tabs, reusable cards |
| Settings.lua | Local settings panel and slash commands |
| Celebration.lua | Bounded passive toast queue; no input interception |
| Bootstrap.lua | Event registration, one-second visible updates, five-second buff polling |

## Portable records

A confirmed Catch Record contains `id`, `provider`, `kind='catch'`, `itemID`,
`link`, `quantity`, optional `quality`, `timestamp`, `zone`, `subzone`,
`character`, a `skill` snapshot, and `evidence`. Score is optional and omitted
when the provider cannot establish an individual catch score.

A score object uses `system`, `value`, `unit`, `scope`, and `higherIsBetter`.
Retail journal observations use `system='anglin-journal-best'` and
`scope='journal'`, plus `speciesID`, `rank`, and `trophy`. They are stored and
displayed separately from confirmed loot. Another provider could produce
`scope='catch'` scores measured in weight without changing the basic catch or
feed shape. Classic support is not implemented.

Feed posts have `version`, `id`, `origin`, `kind`, `author`, `timestamp`, title,
body, location, optional item link / record ID, and an empty `reactions` map.
They embed enough display information to outlive the bounded catch history.
No comments or transport are present.

## Persistence and lifecycle

The root database contains `schema`, `settings`, and `characters`. A future
schema version fails closed, preserving the database. Version 1 is initialized
in place; future migrations belong before normal initialization in Store.Init.
Each character owns counters, history, journal observations, and session state.
Best values never regress on stale asynchronous descriptions.

Session time is bounded by the first and last real fishing activity. The live
display also shows the current idle tail. Recent sessions can resume across a
reload within the idle timeout; longer offline gaps are not counted. Automatic
hiding affects only windows opened automatically, so manual reading is stable.

Version 0.2 adds `feedOnCast=false` and `warningSeconds=60` through existing
default initialization. Schema 1 and all catch/history layouts stay intact.
Older feed posts get friendly wording at render time without rewriting saved
history. `A.buffs` is transient, so classification changes require no migration.
Effects carry a category, optional skill/Perception bonus, timer, and evidence;
the total Fishing modifier remains owned by the profession API. Celebration
levels are interesting, record, and exceptional; scoring thresholds are unchanged.

Optional Retail calls are guarded; missing/restricted values remain unknown.
No protected templates, action hooks, third-party dependencies, addon messages,
or external requests are used. All visual assets are built-in WoW textures.

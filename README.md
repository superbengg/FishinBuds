# Fishin' Buds

**A little company by the water.**

Fishin' Buds is a World of Warcraft fishing companion intended to make fishing
in Azeroth feel social—even when you're fishing alone.

**Fishin' Buds is an early-development Retail WoW prototype, actively being
tested.** Friends, guildmates, testers, and interested anglers are welcome to
follow along.

**v0.2.1 — Consumables & Project Cleanup** supports Retail 12.1 (interface
120100), with fishing instrumentation and local catch/record tracking.

The current Gnomish Field Communicator opens automatically while fishing and
shows fishing skill/effective skill, lures, Perception consumables, and Relaxed
Tea. It tracks sessions, casts, catches, personal history and records, with a
local Feed for rare catches and noteworthy journal improvements.

The long-term identity is **fishing utility + an in-game social fishing feed
presented through an Azeroth-style Gnomish/Goblin communicator**. The social
Feed is central; this should not become merely a statistics or tournament addon.

## Five tabs

| Tab | Philosophy | Current functionality |
| --- | --- | --- |
| Feed | What is happening | Local catches and journal highlights |
| Me | My fishing life | Sessions, buffs, counters and recent catches |
| Buds | My fishing friends/community | Future social functionality |
| Realm | Broader fishing activity | Future realm functionality |
| Records | Fishing history and records | Local catches and journal bests |

All activity is currently local. Future posts may have a small fixed set of
reactions, but **no in-game comments**. See [design and roadmap](DESIGN_ROADMAP.md).
**Buds and social sharing are planned, not implemented.** The longer-term idea
is an asynchronous fishing experience with Buds, catches, records, Trophy
moments, and lightweight reactions.

## Install and use

Copy the addon into `World of Warcraft/_retail_/Interface/AddOns/FishinBuds/`,
with `FishinBuds.toc` directly inside that folder. Enable it in the AddOns list.
Restart WoW for a new installation; use `/reload` for updates.

Cast Fishing to open the Gnomish Field Communicator. Drag its header to move it.
Read skill/effective skill, Lure, Perception phial, Relaxed Tea, location, session
time, casts and catches. Hover readouts for details. Other effects live under Me.

Relaxed Tea recognizes Sanguithorn Tea's **Relaxed** Perception buff separately
from your phial. Bonus values come from readable live English tooltips; unknown
values stay unknown. Exact timers turn amber near their configurable expiry warning.
No item use, casting, looting, networking or screenshots are automated.

Automatic windows hide after 90 seconds of inactivity by default. Manual windows
stay open. Automatic opening selects Feed; switching on every recast is optional.

| Command | Action |
| --- | --- |
| `/fb` | Toggle communicator |
| `/fb show` / `/fb hide` | Explicit visibility |
| `/fb settings` | Visibility, delay, warnings, celebrations and position |
| `/fb status` | Detected skill, consumables, effects and session |
| `/fb debug` | Toggle local diagnostics |
| `/fb timeout 90` | Idle delay, 30–600 seconds |

## Data and accuracy

SavedVariables schema 1 preserves separate character histories: 200 recent
catches, 100 feed posts, 30 sessions, 100 Trophy milestones, bests and lifetime
counters. A catch is one collected fishing-loot item stack. Normal logout/reload
saves data; existing settings and history survive this update.

Journal bests can reflect warband progress; they are not individual fish scores.
**NOW THAT is a nice fish.** remains reserved for exceptional Trophy milestones.
See [API limitations](API_LIMITATIONS.md) for detection boundaries.

## Development

No runtime libraries are required. Run `python tests/run.py` with Python and
`lupa` installed; an optional argument points to the test dependency folder.
Offline tests cover all Lua loading, events, classification, UI calls and
SavedVariables round-trip reloads. The user verified v0.2 in Retail; the v0.2.1
tea row still needs an [in-game check](TESTING.md).

Git ignores account data, local backups, caches and build/editor leftovers.
Never commit WoW WTF/SavedVariables or copy private runtime data into source.
The original v0.1 ZIP remains outside this repository in the sibling backup
folder. Historical milestones are documented, not fabricated as Git tags.

[Architecture](ARCHITECTURE.md) · [Version history](CHANGELOG.md) ·
[Design and roadmap](DESIGN_ROADMAP.md)

## License

Fishin' Buds source is available under the [MIT License](LICENSE).

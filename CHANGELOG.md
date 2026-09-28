# v0.2.1 — Consumables & Project Cleanup

- Recognize Sanguithorn Tea's Relaxed Perception aura in its own category.
- Add a compact tea reading in the existing style, using live bonus/timer data.
- Add Git ignore rules, text normalization, project documentation and a social roadmap.
- Preserve schema 1, all history/settings, fishing logic, and the original backup.

This documents development milestones, not retroactive Git commits or tags.

# v0.2 — From Bros to Buds

- Brass casing details, dark instrument panel, crystal accents, bright selected
  tabs, compact skill and session readings; built-in textures only.
- Separate Lure and Perception readouts with names, readable amounts, countdowns,
  amber expiry warnings, and hover details for multiple active consumables.
- Classify lures, skill buffs, Perception consumables, bait, fishing equipment,
  appearance/bobber effects, other fishing effects, and unidentified effects.
  Fishing For Attention and Oversized Bobbers no longer occupy the lure meter.
- Explicit Haranir/Crystalline Perception phial and Truesight recognition.
  Magnitudes use active tooltip text; unsupported text never becomes a guess.
- Friendlier feed/profile/notebook text, including display of old saved posts.
- Interesting / record / exceptional toast styling. The signature phrase keeps
  its existing strict Trophy threshold.
- Optional Feed selection on every cast and a 15–300 second warning threshold.
  Both new settings are added without resetting any existing setting or history.
- `/fb status` refreshes effects and reports categories, sources, known bonuses,
  timers, and unknowns. Debug messages remain off by default.

Unchanged: cast recognition, loot confirmation and interpretation, counters,
session lifecycle, record scoring, retention, schema 1, and auto-hide rules.
No networking, action automation, sound, screenshots, or external systems added.

Validation: Lua 5.1 regression scenarios, classification fixtures, all tab render
paths, serialization/fresh-runtime SavedVariables reload. Live v0.2 smoke test
subsequently confirmed working by the user. The v0.1 ZIP remains in FishinBuds_Backups.

# v0.1 — Initial working prototype

Core fishing detection, session tracking, personal records, initial local Feed,
five-tab UI, and Gnomish communicator foundation. Verified working in Retail
by the user and preserved in the original dated ZIP backup.

# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Explain repair replacement station-pressure sources.

Status:
Implemented, fully verified, and parent-reviewed; ready to publish.

Selected slice:
Expose deterministic source paths on V2 replacement-ranking rows whenever the
station-pressure penalty comes from allocation evidence, live calendar evidence,
or both.

Why this slice:
The published scoring slice correctly combines and deduplicates exact allocation
and calendar pressure, but ranking explanations expose only the numeric
`station_calendar_pressure_penalty`. Operators must reopen both source reports
to determine which evidence informed a candidate row.

Level 6 pillar:
Fleet-level contact/resource allocation behavior with explainable scoring.

Implemented:
- Pressured replacement-ranking rows now emit a stable ordered
  `station_calendar_pressure_sources` list.
- Allocation-only rows name the source contact-allocation report; calendar-only
  rows name the repair station-calendar report; dual-source rows name both.
- Nominal candidate rows omit the field instead of carrying empty provenance.
- The penalty remains one calibrated unit for any nonempty source list, so
  ranking and final score behavior are unchanged.

Docs changed:
- `docs/feature_set/capability_map/07_ground_network/03_contact_allocation.md`
- `docs/feature_set/capability_map/13_v2_rolling_repair.md`
- `docs/feature_set/recommended_roadmap.md`

Verification:
- Allocation/calendar/exact-fixture focused tests: `7 passed`.
- Campaign-planner area: `754 passed`.
- Full suite with `--timeout 120000`: `3509 passed`.
- `mix compile --warnings-as-errors`, `mix format --check-formatted`, and
  `git diff --check`: passed.

Parent review:
- Source membership uses the same exact candidate-ID sets as the already-
  verified penalty, preventing provenance from diverging from scoring.
- Lexical ordering makes dual-source lists deterministic; nominal rows are
  unchanged, preserving checked-in exact fixture equality.
- Penalty calculation still depends only on empty/nonempty pressure evidence,
  not source count, so dual evidence cannot double charge a candidate.
- The additive ranking explanation grants no provider, schedule, approval,
  import, or execution authority and copies no full source payload.

Previous published slice:
- `1d852177` Score repair allocation capacity pressure (`3509 passed`).

Remaining maturity gaps:
- Continue calibrated realized-feedback depth where evidence is genuinely
  candidate-specific.
- Continue fleet-scale station/allocation decisions while preserving explicit
  provider and Cadence execution boundaries.
- Continue broader schema/versioned compatibility discipline.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent performed bounded
mapping, review, and mechanical publish checks.

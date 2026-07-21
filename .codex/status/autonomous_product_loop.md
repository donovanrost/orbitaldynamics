# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Rank repair replacements with allocation-carried station pressure.

Status:
Implemented, fully verified, and parent-reviewed; ready to publish.

Selected slice:
Apply exact candidate-specific reduced-capacity station evidence from a supplied
contact-allocation report to V2 replacement ranking and final repair scoring.

Why this slice:
V2 already ranks with repair-time station-calendar pressure, but a supplied
candidate refresh can carry the same exact `contact_id`, station availability,
and capacity fraction in `contact_allocation_report.v1`. Viable reduced-capacity
replacements currently lose that signal when no separate ground-network overlay
is provided, even though the allocation report remains in review/import output.

Level 6 pillar:
Fleet-level contact/resource allocation behavior with explainable scoring.

Implemented:
- Added a focused allocation-pressure helper that selects only exact viable
  allocated contact IDs with shared-classifier reduced-capacity evidence.
- V2 replacement ranking now combines those IDs with repair-time calendar
  pressure and applies one calibrated `risk_weight` unit per candidate.
- Final selected-plan scoring adds allocation-carried pressure only for selected
  contacts and deduplicates matching live calendar evidence.
- Deferred, policy-blocked, reserved, nominal, absent, nonmatching, and
  unselected rows remain neutral; review/import evidence stays intact.

Docs changed:
- `docs/feature_set/capability_map/07_ground_network/03_contact_allocation.md`
- `docs/feature_set/capability_map/13_v2_rolling_repair.md`
- `docs/feature_set/recommended_roadmap.md`

Verification:
- Allocation classifier and end-to-end ranking tests: `4 passed`.
- Focused replacement-ranking regression set: `22 passed`.
- Campaign-planner area: `754 passed`.
- Full suite with `--timeout 120000`: `3509 passed`.
- `mix compile --warnings-as-errors`, `mix format --check-formatted`, and
  `git diff --check`: passed.

Parent review:
- Exact allocation IDs are intersected with viable replacement candidates and
  selected repaired activities before affecting ranking or final score.
- A dedicated reduced-capacity classifier avoids treating matched reservations
  as risk; canonical and numeric-string capacity evidence share normalization.
- Calendar/allocation agreement is deduplicated by contact ID while preserving
  both source artifacts for operator review and Cadence import.
- The behavior is a calibrated ranking signal, not hard suppression, provider
  reservation, schedule mutation, approval, import, or execution authority.

Previous published slice:
- `9f286eca` Guard global fixture coverage (`3506 passed`).

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

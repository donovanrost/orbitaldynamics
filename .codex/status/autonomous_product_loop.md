# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Apply repair-time station-calendar pressure during replacement ranking.

Status:
Implemented and verified; publish pending.

Why this slice:
Repair-time station calendars annotated candidates and penalized a selected
affected contact only after replacement selection. A slightly higher-value
reserved contact could therefore win even when a nominal same-station
alternative had the better final repair objective.

Level 6 pillar:
Fleet-level contact/resource behavior plus planner-visible, explainable use of
existing artifact pressure during actual selection.

Behavior/evidence added:
- Derive pressure-bearing candidate IDs from the repair-time
  `station_calendar_report.v1` with the shared station-pressure classifier.
- Within each semantic candidate-diff priority tier, subtract one normalized
  `risk_weight` unit from a pressured candidate's ranking objective.
- Preserve deterministic score/churn/time/ID tie-breakers and the annotation-
  only provider boundary; no candidate suppression or schedule mutation.
- A two-alternative proof shows weight 1.0 selecting the nominal contact and
  omitting selected station pressure, while weight 0.5 still selects the
  reserved higher-value contact and emits the matching `-0.5` score term.
- Unselected affected alternatives remain visible for operator review; a
  selected pressured contact retains operator-review and Cadence-import rows.

Files changed:
- `lib/orbital_dynamics/campaign_planner/repair_execution.ex`
- `lib/orbital_dynamics/campaign_planner/repair_replacement_selection.ex`
- `lib/orbital_dynamics/campaign_planner/repair_score_terms.ex`
- `lib/orbital_dynamics/campaign_planner/station_calendar_pressure_branches.ex`
- `test/orbital_dynamics/campaign_planner/repair_station_calendar_annotation_test.exs`

Docs/artifacts changed:
- V2 repair capability map, recommended roadmap, and rolling-operations planner
  document calibrated station-calendar-aware replacement ranking.
- No checked-in artifact regeneration was required.

Verification:
- Focused station-calendar repair suite: 4 passed.
- All V2 repair tests: 57 passed.
- Full campaign-planner area: 747 passed.
- Full `mix test --timeout 120000`: 3,490 passed.
- Schema lint: 155 artifacts, zero errors/warnings.
- `mix compile --warnings-as-errors`, formatting, and diff checks: pass.

Parent review:
Complete. The parent checked shared-classifier reuse between selection and final
scoring, repair-time report scoping, semantic candidate-diff precedence,
numeric-string risk weights, deterministic tie-breakers, no-report behavior,
score/report omission for the nominal choice, review visibility for the
unselected affected alternative, and review/import preservation for a selected
pressured contact. No must-fix findings remain. Runtime policy disallows
subagent delegation, so the parent performed review and publish prep.

Previous published slice:
- `28e3ac4b` Score repair candidate diff pressure (`3489 passed`).

Remaining maturity gaps:
- Continue calibrated realized-feedback depth and remaining candidate-selection
  alignment with final score components.
- Continue fleet-scale station/allocation decisions while preserving explicit
  provider and Cadence execution boundaries.
- Keep schema/versioned compatibility and golden strategy evidence current as
  selection behavior expands.

Next candidate:
Reassess the remaining V2 replacement-ranking versus final-score gaps and pick
the highest-value pressure term with a deterministic contradictory-selection
repro.

Blocked:
None.

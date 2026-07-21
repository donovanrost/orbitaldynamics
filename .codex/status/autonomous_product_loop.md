# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Apply projected link-capacity shortfall during V2 replacement ranking.

Status:
Implemented and verified; publish pending.

Why this slice:
V2 emitted one normalized `link_capacity_pressure_penalty` when the final
selected timeline missed its downlink requirement, but greedy replacement
ranking ignored that same objective. A higher-value 99 MB candidate could win
over a 100 MB alternative even when the final penalty reversed their scores.

Level 6 pillar:
Fleet-level contact/resource behavior plus reproducible, explainable V2
selection and score alignment.

Behavior/evidence added:
- Extract one canonical repair link-capacity policy for replacement projection
  and the final `link_capacity_report.v1`.
- Project each alternative with already-repaired and not-yet-processed planned
  activities, using a shared selected-shortfall classifier.
- Within each semantic candidate-diff priority tier, subtract one normalized
  `risk_weight` unit when the projected timeline has selected shortfall.
- Preserve deterministic score/churn/time/ID tie-breakers and candidate
  availability; this is calibrated ranking, not hard suppression.
- A two-weight proof includes a later 50 MB planned contact: weight 1.0 selects
  the 50 MB alternative that satisfies a 100 MB total requirement and omits the
  final term, while weight 0.25 selects the higher-value 49 MB alternative and
  emits matching 1 MB shortfall and `-0.25` score/report evidence.
- Final reports are still recomputed after all repairs; documentation labels the
  selection projection as greedy rather than global optimization.

Files changed:
- `lib/orbital_dynamics/campaign_planner/repair_link_capacity_policy.ex`
- `lib/orbital_dynamics/campaign_planner/link_capacity_pressure_branches.ex`
- `lib/orbital_dynamics/campaign_planner/repair_orchestration.ex`
- `lib/orbital_dynamics/campaign_planner/repair_execution.ex`
- `lib/orbital_dynamics/campaign_planner/repair_replacement_selection.ex`
- `lib/orbital_dynamics/campaign_planner/repair_score_terms.ex`
- `test/orbital_dynamics/campaign_planner/repair_link_capacity_requirements_test.exs`

Docs/artifacts changed:
- V2 repair capability map, recommended roadmap, and rolling-operations planner
  document calibrated projected link-capacity ranking and its greedy boundary.
- No checked-in artifact regeneration was required; golden strategy tests pass.

Verification:
- Focused repair link-capacity suite: 5 passed.
- All V2 repair tests: 58 passed.
- Full campaign-planner area: 748 passed.
- Full `mix test --timeout 120000`: 3,491 passed.
- Schema lint: 155 artifacts, zero errors/warnings.
- `mix compile --warnings-as-errors`, formatting, and diff checks: pass.

Parent review:
Complete. The parent checked canonical policy reuse, mission-state requirement
aggregation and scoring-policy precedence, projection composition across
already-repaired and remaining planned activities, shared selected-shortfall
classification, preservation of prior actual-throughput semantics, semantic
candidate-diff precedence, numeric-string weights, deterministic tie-breakers,
score/report omission and emission, schemas, docs, and the explicit greedy
projection limit. No must-fix findings remain. Runtime policy disallows subagent
delegation, so the parent performed review and publish prep.

Previous published slice:
- `427e0720` Align repair selection with station pressure (`3490 passed`).

Remaining maturity gaps:
- Continue calibrated realized-feedback depth and remaining candidate-selection
  alignment, especially selected resource-projection risk.
- Continue fleet-scale station/allocation decisions while preserving explicit
  provider and Cadence execution boundaries.
- Keep schema/versioned compatibility and golden strategy evidence current as
  selection behavior expands.

Next candidate:
Assess whether candidate-specific resource-projection risk can produce a safe,
deterministic V2 selection contradiction without pretending the greedy repair is
a global resource optimizer.

Blocked:
None.

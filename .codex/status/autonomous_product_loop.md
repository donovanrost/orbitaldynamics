# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Apply projected resource risk during V2 replacement ranking.

Status:
Implemented and verified; publish pending.

Why this slice:
V2 final scoring counted every selected resource-projection risk, but
replacement ranking ignored the same candidate-specific evidence even though
canonical resource summaries were available before selection.

Level 6 pillar:
Fleet-level resource behavior plus reproducible, explainable V2 selection and
score alignment.

Behavior/evidence added:
- Pass the exact candidate-refresh resource summaries used by final projection
  into replacement context.
- Project each alternative with already-repaired and not-yet-processed planned
  activities using the same planning-grade resource projector.
- Count candidate pressure with shared
  `ResourceProjectionRisk.risk_indicators/1` and subtract one normalized
  `risk_weight` unit per risk within each semantic candidate-diff priority tier.
- Preserve deterministic score/churn/time/ID tie-breakers and candidate
  availability; this is calibrated ranking, not hard suppression.
- A two-spacecraft proof shows weight 1.0 selecting score-9.5 nominal `leo_2`
  over score-10.0 payload-unavailable `leo_1` and omitting final pressure, while
  weight 0.25 selects `leo_1` and emits matching `payload_unavailable`, `-0.25`
  score/report, operator-review, and Cadence-import evidence.
- Final projection remains authoritative after all repairs; docs preserve the
  thin subsystem-model and greedy-selection limits.

Files changed:
- `lib/orbital_dynamics/campaign_planner/repair_orchestration.ex`
- `lib/orbital_dynamics/campaign_planner/repair_execution.ex`
- `lib/orbital_dynamics/campaign_planner/repair_replacement_selection.ex`
- `test/orbital_dynamics/campaign_planner/repair_resource_projection_test.exs`

Docs/artifacts changed:
- V2 repair capability map, recommended roadmap, and rolling-operations planner
  document calibrated projected resource-risk ranking and its model limits.
- No checked-in artifact regeneration was required; golden strategy tests pass.

Verification:
- Focused repair resource-projection suite: 7 passed.
- All V2 repair tests: 59 passed.
- Full campaign-planner area: 749 passed.
- Full `mix test --timeout 120000`: 3,492 passed.
- Schema lint: 155 artifacts, zero errors/warnings.
- `mix compile --warnings-as-errors`, formatting, and diff checks: pass.

Parent review:
Complete. The parent checked exact normalized resource-summary reuse, projected
activity composition, shared projector and risk enumeration, per-risk numeric-
string weighting, semantic candidate-diff precedence, deterministic tie-breakers,
nominal term omission, pressured score/report/review/import preservation,
schemas, docs, golden stability, and the explicit thin/greedy model boundary.
No must-fix findings remain. Runtime policy disallows subagent delegation, so
the parent performed review and publish prep.

Previous published slice:
- `1d191f1b` Align repair selection with link capacity (`3491 passed`).

Remaining maturity gaps:
- Continue calibrated realized-feedback depth and remaining candidate-specific
  contact/resource evidence during selection.
- Continue fleet-scale station/allocation decisions while preserving explicit
  provider and Cadence execution boundaries.
- Keep schema/versioned compatibility and golden strategy evidence current as
  selection behavior expands.

Next candidate:
Reassess remaining candidate-specific contact/allocation pressure versus source-
wide provenance, and only select a ranking slice if a stable candidate identity
can be mapped without inventing semantics.

Blocked:
None.

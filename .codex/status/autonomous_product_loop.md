# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Preserve V2 replacement-ranking evidence in selected activity metadata.

Status:
Implemented, fully verified, and parent-reviewed; ready to publish.

Selected slice:
Expose the viable-candidate ranking rows that explain a moved downlink or
reassigned observation choice.

Why this slice:
V2 replacement ranking now internalizes semantic candidate-diff priority,
candidate value, churn, station-calendar pressure, projected link shortfall,
and projected resource risks. Before this slice, the selected activity recorded
only action, reason, and churn; when a nominal candidate won, final conditional
pressure terms disappeared and the artifact could not explain why the
higher-value alternative lost.

Level 6 pillar:
Reproducible V2/V3 branch trees with explainable score terms and deltas.

Implemented:
- `RepairReplacementSelection` now keeps a compact ranked row for every viable,
  unique candidate and returns the selected candidate with deterministic
  ranking evidence.
- Rows preserve semantic candidate-diff match/priority, candidate score, churn,
  schedule-move, station-calendar, projected link-capacity, and projected
  resource contributions, final ranking score, rank, and selected flag.
- Moved downlinks and reassigned observations attach the evidence at
  `repair.replacement_ranking`, declare greedy/non-global scope, and do not copy
  candidate payloads.
- Duplicate-ID and rejected candidates remain outside the evidence scope;
  focused tests pin both exclusions.
- The deterministic repair-readiness source-handoff fixture was regenerated
  only after proving the generated artifact differed at the new ranking path,
  and its contract test now pins the exact row shape.

Docs to read:
- `docs/feature_set/capability_map/13_v2_rolling_repair.md`
- `docs/mission_planning/leo_campaign_planner/02_v2_rolling_operations_planner.md`

Artifacts and docs:
- `study_results/campaign_repair_readiness_source_handoff_v2.json`
- `docs/artifacts/field_families/v2_repair_artifact.md`
- `docs/feature_set/capability_map/13_v2_rolling_repair.md`
- `docs/mission_planning/leo_campaign_planner/02_v2_rolling_operations_planner.md`

Verification:
- Focused semantic-diff, station-calendar, link-capacity, and resource-projection
  ranking proofs: `17 passed`.
- Focused duplicate/rejected-candidate scope proofs: `3 passed`.
- Deterministic source-handoff fixture contract: `1 passed`.
- All V2 repair tests: `59 passed`.
- Campaign-planner area, including checked strategy golden: `749 passed`.
- Full suite: `3493 passed`.
- Checked artifacts: `155` passed schema lint with zero errors or warnings.
- `mix compile --warnings-as-errors`, `mix format --check-formatted`, and
  `git diff --check`: passed.

Parent review:
- Ranking sort semantics are unchanged: semantic-diff priority, descending
  ranking score, churn, start time, then candidate ID.
- Signed contribution fields reconcile with the prior score formula and
  normalize zero penalties to `0.0` rather than `-0.0`.
- Evidence scope is exactly the viable, unique candidate set after horizon,
  degraded-mode, rejection, overlap, repair-intent, and duplicate-ID filters.
- Rows contain identifiers and scalar explanations only; no alternative
  candidate payload or provider/Cadence execution boundary was introduced.
- The checked-in fixture was inspected before regeneration and changed only by
  the expected nested ranking evidence.

Previous published slice:
- `4a79e588` Guard resource contact fixture coverage (`3493 passed`).

Remaining maturity gaps:
- Continue calibrated realized-feedback depth where evidence is genuinely
  candidate-specific.
- Continue fleet-scale station/allocation decisions while preserving explicit
  provider and Cadence execution boundaries.
- Continue broader schema/versioned compatibility discipline.

Blocked:
None.

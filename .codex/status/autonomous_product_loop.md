# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Apply exact candidate-scoped blocked quality gates during CandidateRefresh.

Status:
Implemented, fully verified, and parent-reviewed; ready to publish.

Selected slice:
Reject a regenerated candidate when a canonical blocked quality-gate report is
explicitly scoped to that candidate's planned-activity identity.

Why this slice:
CandidateRefresh preserved and scored quality-gate replay pressure, but general
blocked quality-gate reports remained provenance-only even when their
`source_artifact_id` exactly named one regenerated candidate. The only prior
selection effect was specialized unavailable-resource contact evidence.

Level 6 pillar:
Refreshed candidates from current mission state with approval-aware quality
gates and import boundaries.

Implemented:
- CandidateRefresh now recognizes a candidate-scoped source only when the
  resolved input is a schema-valid `quality_gate_report.v1`, its status is
  blocked, its source type is `planned_activity.v1`, and its non-empty
  `source_artifact_id` exactly matches the generated candidate ID.
- Rejected candidates carry deterministic quality-gate report/summary identity,
  source path, candidate ID, status, selection scope, and inherited trust
  boundary in `candidate_rejection_report.v1` provenance.
- Matching prior candidates use
  `dropped_by_candidate_scoped_quality_gate`; builds emit a distinct warning and
  reuse the existing candidate-rejection operator-review/Cadence-import handoff.
- Generic compact summaries, invalid reports, row-ID-only matches, wrong source
  types, nonmatching IDs, and review-only/analysis-only/passed reports remain
  selection-neutral. The specialized unavailable-resource rule remains
  unchanged.

Docs changed:
- `docs/feature_set/capability_map/11_planning_state_refresh/refresh_pipeline_and_provenance.md`
- `docs/feature_set/capability_map/20_cadence_boundary_and_integration_artifacts.md`
- `docs/artifacts/field_families/candidate_refresh_artifact.md`
- `docs/feature_set/recommended_roadmap.md`

Verification:
- Focused quality-gate selection/neutrality tests: `5 passed`.
- Legacy unavailable-resource/readiness/allocation selection proofs: `13 passed`.
- CandidateRefresh area: `768 passed`.
- Campaign-planner area: `749 passed`.
- Full suite: `3495 passed`.
- Checked artifacts: `155` passed schema lint with zero errors or warnings.
- `mix compile --warnings-as-errors`, `mix format --check-formatted`, and
  `git diff --check`: passed.

Parent review:
- Selection cannot be activated by aggregate status, candidate-shaped row IDs,
  compact summaries, or malformed report-shaped maps; executable schema
  validation is required before exact identity matching.
- The filter runs after contact gating and before resource/allocation/budget
  filtering, so observations and contacts share the same bounded activity rule
  without bypassing later constraints.
- Existing spacecraft-scoped unavailable-resource provenance retains its prior
  field names and behavior; new selection-scope fields appear only for the new
  candidate-artifact path.
- Outputs remain artifact-only: no Cadence write, approval, provider action,
  schedule mutation, or execution authority was added.

Previous published slice:
- `4e0d529b` Explain repair replacement ranking (`3493 passed`).

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

# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Route V1 constraint reports through executable validation.

Status:
Implemented, fully verified, and parent-reviewed; ready to publish.

Selected slice:
Declare `constraint_report.v1` as an optional V1 nested contract, run its full
runtime validator, and pin its campaign-plan model/source context.

Why this slice:
V1 emits a row-oriented constraint report, but the campaign contract neither
declares nor validates it. Impossible counts/status maps, malformed rows, wrong
models, or stale source assumptions can therefore pass inside a valid plan.

Level 6 pillar:
Versioned compatibility and explainable operational-planning handoffs.

Implemented:
- `campaign_plan.v1` declares `constraint_report` as optional and
  `constraint_report.v1` as a direct nested contract.
- Embedded reports run the standalone required-field, row, count, status-map,
  status, model, and model-limit validations.
- V1 context requires the campaign-planner model, V1 constraint assumptions,
  and `campaign_plan.assumptions.constraints` source.
- A reusable decision-support optional router rejects non-object reports while
  preserving omission compatibility.

Docs changed:
- `docs/feature_set/capability_map/12_v1_campaign_planning.md`
- `docs/feature_set/capability_map/17_reproducibility_artifacts_and_audit.md`
- `docs/feature_set/recommended_roadmap.md`

Verification:
- Focused routing/export/generated-plan tests: `32 passed`.
- Schema area: `216 passed`.
- Campaign-planner area: `754 passed`.
- Full suite with `--timeout 120000`: `3541 passed`.
- `mix compile --warnings-as-errors`, `mix format --check-formatted`, and
  `git diff --check`: passed.

Parent review:
- Validation is additive and preserves optional omission.
- Standalone checks own row/count/status/model-limit integrity; the V1 module
  adds only campaign-specific model/source semantics.
- Exact and mutation tests cover wrong V1 context, stale derived counts/status,
  malformed row/operator/model limits, and non-object reports without crashes.
- Schema regeneration changed only the V1 campaign export and its bundle entry,
  embedding the existing standalone contract definition.

Previous published slice:
- `b9319604` Validate V1 optimizer handoffs (`3536 passed`).

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
mapping, implementation, review, and mechanical publish checks.

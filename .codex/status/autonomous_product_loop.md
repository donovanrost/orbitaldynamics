# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Contract V1 plan provenance.

Status:
Complete and parent-reviewed; ready to publish.

Delivered:
- Required the five provenance fields emitted by every current V1 producer.
- Kept run ID, manifest, git revision, propagator, and propagator options
  nullable for direct planning over an existing result set.
- Typed non-null scalar/map values and rejected blank run/revision/propagator
  strings.
- Validated supplied manifest paths as non-empty strings and SHA-256 evidence as
  exact lowercase 64-character digests.
- Exported the same required keys, nullable types, and manifest rules in JSON
  Schema.
- Covered checked-in file-backed evidence and fresh direct-build null evidence.
- Aligned the lint task's serialized nominal fixture with required JSON-null
  provenance; no runtime producer or compatibility behavior was changed.
- Regenerated only `campaign_plan.v1` and the aggregate schema bundle.
- Updated V1 generation, planning, reproducibility, and roadmap documentation.

Review calibration:
- `CampaignPlanner.PlanMetadata.provenance/1` always produces the five required
  keys; direct and file-backed plans differ only in available evidence values.
- Elixir `nil` correctly covers direct in-memory plans, while OTP JSON encoding
  requires `:null` in the lint fixture to emit a JSON null rather than `"nil"`.
- Parent review found the focused validator cohesive at 62 lines and retained
  extensible manifest/provenance maps without inventing unavailable evidence.

Verification:
- Focused plan/export integration: `26 passed`.
- Schema area: `274 passed`; combined schema plus lint: `286 passed`.
- Planner area: `754 passed`.
- Full suite: `3599 passed`.
- `mix format --check-formatted`, `mix compile --warnings-as-errors`, and
  `git diff --check` pass.

Previous published slice:
- `a66a3308` Validate V1 plan assumptions (`3592 passed`).

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

# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
CandidateRefresh quality-gate schema-validation status-ID replay.

Status:
Completed locally; product commit created and handoff updated.

Slice-selection note:
Selected slice:
Preserve quality-gate schema-validation status IDs through CandidateRefresh
source-report and compact quality-gate replay summaries.

Why this slice:
`operational_quality_gate_schema_validation_summary.v1` exposes
`schema_validation_status_ids`, but CandidateRefresh quality-gate replay only
preserves schema-validation status counts, failed quality-gate row IDs, and gate
IDs. Branch-local schema-blocker queues lose the compact status-ID routing
unless they reopen the source summary.

Level 6 pillar:
Approval-aware automation boundaries, durable schema-versioned artifacts, and
refreshed candidates from current source-report evidence.

Current evidence gap:
CandidateRefresh quality-gate provenance and `quality_gate_replay_summary/1`
do not preserve `schema_validation_status_ids`.

Docs to read:
- `docs/artifacts/field_families/candidate_refresh_artifact.md`
- `docs/feature_set/capability_map/20_cadence_boundary_and_integration_artifacts.md`
- `docs/mission_planning/high_fidelity/12_operational_readiness.md`

Likely files:
- `lib/orbital_dynamics/candidate_refresh.ex`
- `lib/orbital_dynamics/schema.ex`
- `test/orbital_dynamics/candidate_refresh_test.exs`
- `test/orbital_dynamics/schema_test.exs`
- generated CandidateRefresh schemas and bundle if schema-visible
- `docs/artifacts/field_families/candidate_refresh_artifact.md`
- `docs/feature_set/capability_map/20_cadence_boundary_and_integration_artifacts.md`

Likely tests:
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:<schema-validation replay selector>`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:<wrapped schema-validation replay selector>`
- focused CandidateRefresh source-report schema validation selector if schema-visible
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix orbital_dynamics.schema.lint --all`
- `git diff --check`

Definition of done:
- CandidateRefresh source-report summaries preserve `schema_validation_status_ids`.
- Compact quality-gate replay exposes those status IDs for direct and wrapped
  schema-validation summaries.
- Schema validation/export covers the field when schema-visible.
- Focused tests cover direct and wrapped summary replay.
- Docs describe branch-local schema-validation status routing without implying
  import approval, Cadence write, or schema certification.

Previous pushed slice:
Provider reservation request direction-station routing landed in product commit
`272f302` and final pushed ledger commit `b658d89`, with local and `origin/main`
verified at `b658d891992fb796e5aeef7f9126dcb7d2e83ee4`.

Completed slice:
CandidateRefresh quality-gate schema-validation status-ID replay landed in
product commit `78615e9`. CandidateRefresh source-report summaries and compact
quality-gate replay now preserve `schema_validation_status_ids` from direct,
accepted-state, mission-state, and wrapped
`operational_quality_gate_schema_validation_summary.v1` handoffs. Candidate
refresh provenance schema/export exposes the list as optional strings and
executable validation rejects malformed list items. Docs describe branch-local
schema-validation status routing without adding import approval, Cadence write,
or schema certification.

Verification:
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:31559 test/orbital_dynamics/candidate_refresh_test.exs:31716 test/orbital_dynamics/schema_test.exs:15879`
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix orbital_dynamics.schema.lint --all`
- `git diff --check`

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Blocked:
No.

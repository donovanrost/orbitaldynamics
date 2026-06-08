# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Publication downstream invalidation reason routing.

Status:
Implemented, locally reviewed, parent-verified, and committed. Timeline
publication summaries now distinguish downstream invalidation reasons as
dependency-impact review, explicit downstream invalidation, or superseded
publication. Operator review rows, Cadence import rows, CandidateRefresh source
reports, and CandidateRefresh replay summaries preserve the reason counts and
reason-keyed invalidated downstream product IDs, including row-only handoffs.

Files changed:
- `docs/artifacts/field_families/mission_activities.md`
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/candidate_refresh.ex`
- `lib/orbital_dynamics/operator_review.ex`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/timeline.ex`
- `lib/orbital_dynamics/validation.ex`
- `schemas/cadence_import_manifest.v1.schema.json`
- `schemas/campaign_plan.v1.schema.json`
- `schemas/campaign_repair.v2.schema.json`
- `schemas/campaign_strategy.v3.schema.json`
- `schemas/candidate_refresh.v1.schema.json`
- `schemas/operational_execution_boundary_summary.v1.schema.json`
- `schemas/operational_import_eligibility_summary.v1.schema.json`
- `schemas/operational_quality_gate_import_readiness_summary.v1.schema.json`
- `schemas/operational_quality_gate_operator_training_summary.v1.schema.json`
- `schemas/operational_quality_gate_schema_validation_summary.v1.schema.json`
- `schemas/operational_quality_gate_summary.v1.schema.json`
- `schemas/operational_quality_gate_unavailable_resource_summary.v1.schema.json`
- `schemas/operational_readiness_gate_summary.v1.schema.json`
- `schemas/operational_readiness_report.v1.schema.json`
- `schemas/operator_review_package.v1.schema.json`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `schemas/quality_gate_report.v1.schema.json`
- `schemas/realized_state_snapshot.v1.schema.json`
- `schemas/study_manifest.v1.schema.json`
- `schemas/timeline_feedback_report.v1.schema.json`
- `schemas/timeline_publication_summary.v1.schema.json`
- `schemas/validation_safety_case_summary.v1.schema.json`
- `study_results/timeline_publication_summary_v1.json`
- `study_results/validation_reference_fixtures.json`
- `.codex/status/autonomous_product_loop.md`
- `test/orbital_dynamics/cadence_import_test.exs`
- `test/orbital_dynamics/candidate_refresh_test.exs`
- `test/orbital_dynamics/operator_review_test.exs`
- `test/orbital_dynamics/schema_test.exs`
- `test/orbital_dynamics/timeline_test.exs`
- `test/orbital_dynamics/validation_test.exs`

Tests run:
- `mix compile`
- `mix test test/orbital_dynamics/timeline_test.exs:3675 test/orbital_dynamics/operator_review_test.exs:2477 test/orbital_dynamics/cadence_import_test.exs:13610 test/orbital_dynamics/candidate_refresh_test.exs:26442 test/orbital_dynamics/candidate_refresh_test.exs:26644 test/orbital_dynamics/schema_test.exs:26046 test/orbital_dynamics/validation_test.exs:9745` (7 passed)
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix orbital_dynamics.manifest.schema.export --output schemas/study_manifest.v1.schema.json`
- `mix test test/orbital_dynamics/study/manifest_test.exs:730` (1 passed)
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:26644` (1 passed)
- `mix test test/orbital_dynamics/timeline_test.exs test/orbital_dynamics/operator_review_test.exs test/orbital_dynamics/cadence_import_test.exs test/orbital_dynamics/candidate_refresh_test.exs test/orbital_dynamics/schema_test.exs test/orbital_dynamics/validation_test.exs` (1522 passed)
- `git diff --check`
- `mix orbital_dynamics.schema.lint --all` (154 files, 154 artifacts, status pass)
- `mix test` (3227 passed; known `:propagator_exit` test log observed and suite exited green)

Docs/artifacts changed:
- Updated mission-activity artifact-family docs to state publication summaries
  preserve downstream invalidation reasons through review/import and
  CandidateRefresh handoffs.
- Regenerated timeline publication summary and validation reference fixtures.
- Regenerated full schema exports and the study manifest schema export touched by
  embedded publication-summary schema drift.

Local review:
- Found and fixed one compatibility edge: older row-only review/import handoffs
  without the new reason fields could reconstruct nil reason maps before replay
  pressure checks. CandidateRefresh now normalizes those maps to `%{}` and has a
  regression asserting legacy row-only replay stays importable while preserving
  invalidation pressure from invalidated IDs.
- No subagent reviewer was spawned in this continuation because the available
  delegation tool requires an explicit user request for subagents in the current
  turn.

Level 6 pillar advanced:
Durable schema-versioned publication semantics and approval-aware Cadence
handoff artifacts. Downstream products can now route invalidation by reason
instead of inferring from status and IDs alone, and stale reason fields are
rejected by runtime validation when present.

Remaining maturity gaps:
Resource/contact allocation still needs deeper planner-visible behavior for
provider-calendar capacity and reservation pressure during candidate selection.
Typed timeline lifecycle/publication semantics still need broader publication
hardening beyond this downstream invalidation reason slice.

Last commit:
`7b02d2b` Route publication invalidation reasons.

Next candidate:
Reassess Level 6 gaps from the guide/ledger. Likely candidates include
planner-visible reduced-capacity/contact-allocation behavior in branch-local
candidate refresh, or continued publication/lifecycle hardening around explicit
operator approval and downstream import authority.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Previous published slice:
- `7b02d2b` routed publication invalidation reasons.
- `f433cbf` preserved publication dependency lineage.
- `05a0f69` updated the precondition evidence handoff.
- `3818b51` preserved duplicate precondition evidence.
- `7dfb84a` updated the provider replay handoff.

Blocked:
No.

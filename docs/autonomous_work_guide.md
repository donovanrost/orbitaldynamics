# Autonomous Work Guide

This guide is the first document an autonomous Codex goal loop should read.
Its job is to keep long-running implementation work focused without loading the
entire document base into context.

## Working Rule

Do not read every planning document before choosing work. Start with the
decision queue below, then open only the docs for the selected slice.

For each slice:

1. Pick the highest-priority slice that is not already implemented.
2. Read the linked capability docs and the relevant code/tests.
3. Optionally delegate `slice_mapper` for bounded read-only mapping if the edit
   surface is not obvious.
4. Implement one vertical behavior change.
5. Add or update tests.
6. Update docs and artifacts only where the public behavior changed.
7. Run targeted tests, then broader tests when planner/schema behavior changed.
8. Update `.codex/status/autonomous_product_loop.md`.
9. Delegate `slice_reviewer` for read-only review of the completed slice.
10. Fix must-fix review findings, rerun focused verification, and update the
    ledger if needed.
11. Delegate a weaker commit/push subagent for the completed slice.
12. Repeat.

Use project-scoped custom agents when available:

- `slice_mapper` from `.codex/agents/slice-mapper.toml`
- `slice_reviewer` from `.codex/agents/slice-reviewer.toml`
- `git_slice_publisher` from `.codex/agents/git-slice-publisher.toml`

The parent orchestrator keeps ownership of slice selection, implementation,
focused test/debug loops, done/not-done calls, and ledger updates. Mapper and
reviewer agents are read-only sidecars; they should not edit code, broaden the
slice, or make product decisions.

The commit/push subagent is a mechanical handoff, not a product agent. Use the
project-scoped `git_slice_publisher` custom agent from
`.codex/agents/git-slice-publisher.toml` when available. If that custom agent is
unavailable, prefer `gpt-5.4-mini`; otherwise use the smallest/lowest-cost
coding model available without blocking the handoff. It should stage only the
completed slice's files, commit with a concise message, push the current branch,
and report the commit SHA plus any uncommitted unrelated files. It must not make
product decisions, stage unrelated dirty work, amend/rebase, reset, force-push,
delete branches, or change remotes. If push is blocked by credentials, network
approval, or other external state, keep the local commit and record the blocker
in `.codex/status/autonomous_product_loop.md`.

## Current Decision Queue

### 1. Typed Operational Activity And Timeline Semantics

Why this is first:
V1/V2/V3 already emit timeline and review artifacts, but much behavior still
depends on map conventions. First-class activity semantics make later resource,
policy, merge, and quality-gate work safer.

Good slices:

- normalize planned/realized activity state through a public API
- add status and approval transition helpers
- add dependency and exclusivity validation
- promote lifecycle/lock/executed preservation into reusable helpers
- add candidate rejection or timeline transition reports

Read:

- [feature_set/capability_map/08_mission_activities_and_timelines.md](feature_set/capability_map/08_mission_activities_and_timelines.md)
- [mission_planning/high_fidelity/02_state_activities_and_resources.md](mission_planning/high_fidelity/02_state_activities_and_resources.md)
- [mission_planning/high_fidelity/04_plan_structure_and_lifecycle.md](mission_planning/high_fidelity/04_plan_structure_and_lifecycle.md)
- [artifacts/field_families/mission_activities.md](artifacts/field_families/mission_activities.md)

Likely code/tests:

- `lib/orbital_dynamics/timeline.ex`
- `lib/orbital_dynamics/timeline_feedback.ex`
- `lib/orbital_dynamics/operator_review.ex`
- `lib/orbital_dynamics/schema.ex`
- `test/orbital_dynamics/timeline_test.exs`
- `test/orbital_dynamics/timeline_feedback_test.exs`
- `test/orbital_dynamics/operator_review_test.exs`

### 2. Resource And Communications Allocation Semantics

Why this is second:
The planner has resource summaries, station calendars, contact filters, and
contention reports. The next useful product step is making allocation and
contention semantics more explicit, especially for station reservations and
storage/downlink pressure.

Good slices:

- harden reserved/unavailable/reduced-capacity precedence
- add contact allocation or reservation conflict reports
- add storage/downlink roll-forward behavior for selected activities
- add quality-gate rows for unavailable resources
- make provider counteroffers or reservation holds explicit artifacts

Read:

- [feature_set/capability_map/07_ground_network_and_communications_planning.md](feature_set/capability_map/07_ground_network_and_communications_planning.md)
- [feature_set/capability_map/06_spacecraft_and_payload_modeling.md](feature_set/capability_map/06_spacecraft_and_payload_modeling.md)
- [mission_planning/high_fidelity/01_digital_twin_and_subsystem_models.md](mission_planning/high_fidelity/01_digital_twin_and_subsystem_models.md)
- [mission_planning/high_fidelity/06_operational_concerns.md](mission_planning/high_fidelity/06_operational_concerns.md)
- [artifacts/field_families/candidate_refresh_artifact.md](artifacts/field_families/candidate_refresh_artifact.md)

Likely code/tests:

- `lib/orbital_dynamics/resource_summary.ex`
- `lib/orbital_dynamics/communications/station_calendar.ex`
- `lib/orbital_dynamics/communications/contact_intent.ex`
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/candidate_refresh.ex`
- `test/orbital_dynamics/resource_summary_test.exs`
- `test/orbital_dynamics/communications/station_calendar_test.exs`
- `test/orbital_dynamics/candidate_refresh_test.exs`
- `test/orbital_dynamics/campaign_planner_test.exs`

### 3. Quality Gates, Readiness, And Import Eligibility

Why this is third:
Cadence-facing artifacts need a concise machine-readable way to say whether a
plan is importable, review-only, analysis-only, or blocked.

Good slices:

- add `quality_gate_report.v1`
- add `operational_readiness_report.v1`
- add not-for-execution markings for simulations and trade studies
- add quality-gate rows to operator-review packages
- add import-readiness schema/export tests

Read:

- [feature_set/capability_map/17_reproducibility_artifacts_and_audit.md](feature_set/capability_map/17_reproducibility_artifacts_and_audit.md)
- [feature_set/capability_map/20_cadence_boundary_and_integration_artifacts.md](feature_set/capability_map/20_cadence_boundary_and_integration_artifacts.md)
- [mission_planning/high_fidelity/09_security_and_modes.md](mission_planning/high_fidelity/09_security_and_modes.md)
- [mission_planning/high_fidelity/12_operational_readiness.md](mission_planning/high_fidelity/12_operational_readiness.md)
- [artifacts/compatibility_checks.md](artifacts/compatibility_checks.md)

Likely code/tests:

- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/operator_review.ex`
- `lib/orbital_dynamics/policy.ex`
- `lib/orbital_dynamics/result_set/artifact.ex`
- `test/orbital_dynamics/schema_test.exs`
- `test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `test/orbital_dynamics/operator_review_test.exs`

### 4. Branch-Local Candidate Refresh Depth

Why this is fourth:
Candidate refresh exists and V2/V3 can consume it. The remaining value is
making more mission-state changes generate executable refresh requests and
preserving the explanations through strategy and operator review.

Good slices:

- derive refresh requests from one new source-report family
- preserve candidate-diff reasons through one more V2/V3 path
- add branch-local resource/contact feedback into refresh provenance
- add a compact source-report replay helper rather than another ad hoc branch

Read:

- [feature_set/capability_map/11_planning_state_refresh_and_opportunity_generation.md](feature_set/capability_map/11_planning_state_refresh_and_opportunity_generation.md)
- [feature_set/capability_map/13_v2_rolling_repair.md](feature_set/capability_map/13_v2_rolling_repair.md)
- [feature_set/capability_map/14_v3_strategy_orchestration.md](feature_set/capability_map/14_v3_strategy_orchestration.md)
- [artifacts/field_families/candidate_refresh_artifact.md](artifacts/field_families/candidate_refresh_artifact.md)

Likely code/tests:

- `lib/orbital_dynamics/candidate_refresh.ex`
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/operator_review.ex`
- `test/orbital_dynamics/candidate_refresh_test.exs`
- `test/orbital_dynamics/campaign_planner_test.exs`

### 5. Validation, Compatibility, And Challenge Fixtures

Why this is fifth:
Once public artifacts grow, compatibility and challenge tests prevent the
planner from producing convincing but unsafe outputs.

Good slices:

- add a model acceptance or safety-case report
- add interoperability fixtures for one artifact family
- add challenge tests for stale-but-plausible inputs
- add schema migration/deprecation report support

Read:

- [feature_set/capability_map/18_validation_and_verification.md](feature_set/capability_map/18_validation_and_verification.md)
- [mission_planning/high_fidelity/11_verification_and_validation.md](mission_planning/high_fidelity/11_verification_and_validation.md)
- [artifacts/compatibility_checks.md](artifacts/compatibility_checks.md)

Likely code/tests:

- `lib/orbital_dynamics/validation.ex`
- `lib/orbital_dynamics/schema.ex`
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/golden_artifact_test.exs`
- `test/mix/tasks/orbital_dynamics.schema.export_test.exs`

## Slice Acceptance Checklist

Every implemented slice should satisfy the relevant items:

- public behavior exists behind a module or facade, not only a doc entry
- artifact shape is deterministic for fixed inputs
- schema validation exists for new public artifact contracts
- tests cover normal, edge, and invalid inputs where applicable
- docs name the feature's real maturity level
- assumptions, provenance, validation level, and known limits are explicit
- existing V1/V2/V3 artifacts remain compatible unless versioned deliberately
- `slice_reviewer` found no must-fix publish blockers, or the parent fixed them
  and reran focused verification
- slice changes are committed and pushed, or a local commit/push blocker is
  recorded in `.codex/status/autonomous_product_loop.md`

## Context Control

Use these entry points instead of broad reads:

- implementation queue: this file
- current roadmap: [feature_set/recommended_roadmap.md](feature_set/recommended_roadmap.md)
- high-fidelity future map: [mission_planning/high_fidelity/README.md](mission_planning/high_fidelity/README.md)
- artifact fields: [artifacts/README.md](artifacts/README.md)
- LEO V1/V2/V3 product shape: [mission_planning/leo_campaign_planner/README.md](mission_planning/leo_campaign_planner/README.md)

Avoid reading all files under `docs/` unless the task is explicitly a
documentation restructure.

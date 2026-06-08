# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Reject stale lifecycle-state protection decisions.

Status:
Implemented and parent-verified. `timeline_activity_lifecycle_state.v1`
validation now rejects stale nested planned/realized protection decisions that
conflict with copied executed, locked, or approval-category evidence.

Slice-selection note:
- Selected slice: reject stale `planned_protection_decision` /
  `realized_protection_decision` evidence in `timeline_activity_lifecycle_state.v1`.
- Why this slice: after timeline pressure reached branch scoring, the top
  typed-timeline queue points at malformed/stale lifecycle/protection challenge
  coverage; live validation accepts an executed realized activity whose nested
  protection decision was copied as mutable.
- Level 6 pillar: durable schema-versioned artifacts, approval-aware
  automation boundaries, reusable typed timeline semantics, and Cadence-facing
  adapter preflight evidence.
- Current evidence gap: lifecycle-state artifacts can preserve stale nested
  protection decisions that disagree with copied executed/locked/approval
  fields, weakening review/import preflight trust.
- Docs read:
  `docs/autonomous_work_guide.md`,
  `.codex/prompts/long_running_context_efficient_product_loop.md`,
  `docs/feature_set/completeness_levels/06_mature_operational_platform.md`,
  `docs/feature_set/definition_of_feature_complete.md`,
  `docs/feature_set/current_capability_snapshot.md`,
  `docs/feature_set/recommended_roadmap.md`,
  `docs/feature_set/capability_map/08_mission_activities_and_timelines.md`,
  `docs/mission_planning/high_fidelity/04_plan_structure_and_lifecycle.md`,
  `docs/artifacts/field_families/mission_activities.md`.
- Likely files: `lib/orbital_dynamics/schema.ex`,
  `test/orbital_dynamics/timeline_test.exs`,
  `.codex/status/autonomous_product_loop.md`.
- Definition of done: executable validation rejects stale planned/realized
  protection decisions that conflict with lifecycle-state booleans/categories,
  focused stale-evidence tests pass, schema export/lint impact is checked, and
  whitespace checks are clean.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/schema.ex`
- `test/orbital_dynamics/timeline_test.exs`

Tests run:
- `mix run -e ... Schema.validate_artifact(stale lifecycle state)` showed stale
  realized protection decision was previously accepted.
- `mix format lib/orbital_dynamics/schema.ex test/orbital_dynamics/timeline_test.exs`
- `mix test test/orbital_dynamics/timeline_test.exs:7432` (1 passed, 126 excluded)
- `mix compile --warnings-as-errors`
- `mix test test/orbital_dynamics/timeline_test.exs:7432 test/orbital_dynamics/timeline_test.exs:7725` (2 passed, 125 excluded)
- `mix orbital_dynamics.schema.lint --all` (154 artifacts, status pass)
- `git diff --check`

Docs/artifacts changed:
- None; this is executable validation and challenge-test coverage for the
  documented lifecycle-state contract.

Local review:
- Planned/realized lifecycle-state validation now pins nested protection
  decisions back to copied `*_executed`, `*_locked`, and
  `*_approval_category` evidence when those fields are present.
- Focused tests cover stale executed protection decision, stale executed
  protection category, stale approval flag evidence, planned-side stale
  protection, and the allowed locked/approved `review_change` case.
- Read-only reviewer found no required fixes; suggested positive planned-side
  and `review_change` hardening assertions were added and verified.

Level 6 pillar advanced:
Lifecycle-state artifacts now reject stale protection evidence before
Cadence-facing review/import preflight uses it as adapter evidence.

Remaining maturity gaps:
High-fidelity dynamics, frame/time transformations, external validation
evidence, external orbit-data ingestion, stronger schema-version migration
discipline, provider-write/notification workflows owned outside this library,
and deeper planner-visible use of resource/contact/readiness evidence during
candidate selection and V2/V3 branch scoring.

Last commit:
`4796e0e` Reject stale lifecycle protection evidence.

Next candidate:
After this slice, continue guide-priority lifecycle challenge coverage or move
to external validation/schema-versioning gaps after live-state inspection.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Previous published slices:
- `4796e0e` rejected stale lifecycle-state protection evidence.
- `9fdfb3a` derived timeline publication summary pressure branches.
- `9c45b20` derived timeline dependency-impact summary pressure branches.
- `b9fed8e` derived timeline-integrity report pressure branches.
- `7ebe694` derived prior-plan contact-allocation summary pressure branches.
- `a97d1ca` derived mission-state contact-allocation summary pressure branches.
- `27ab76f` added hold import-readiness direction routing.
- `cb62212` flattened reservation-conflict direction handoffs.
- `cd331cf` flattened station-pressure direction handoffs.
- `0c7c0e2` flattened capacity-pack direction handoffs.

Blocked:
No.

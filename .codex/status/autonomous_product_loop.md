# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Selected transition integrity evidence expansion.

Status:
Implemented, reviewed, committed, and ready to push.

Slice-selection note:
Selected slice:
Extend selected-activity timeline-integrity gate evidence emitted by transition
helpers so it preserves the same dependency/exclusivity issue ID families that
`timeline_integrity_report.v1` exposes.

Why this slice:
Timeline transition helpers already gate selected activities that carry
dependency or exclusivity integrity issues, but their selected-integrity
evidence currently includes only issue types, full issues, missing dependency
IDs, and self-dependency IDs. Duplicate dependencies, duplicate exclusivity,
dependency cycles, dependency order violations, and exclusivity overlaps remain
visible in the selected activity but are not lifted to the transition decision
or application row where operator-review routing usually looks first.

Level 6 pillar:
Typed operational activity and timeline semantics; approval-aware automation
boundaries for Cadence-facing transition artifacts.

Current evidence gap:
`Timeline.integrity_report/2` exposes full dependency/exclusivity issue ID
families, while `Timeline.transition_application*` selected-integrity gate
metadata carries only a subset of those issue families.

Docs to read:
- `docs/feature_set/capability_map/08_mission_activities_and_timelines.md`
- `docs/mission_planning/high_fidelity/04_plan_structure_and_lifecycle.md`
- `docs/artifacts/field_families/mission_activities.md`

Likely files:
- `lib/orbital_dynamics/timeline.ex`
- `lib/orbital_dynamics/operator_review.ex`
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/schema.ex`
- `test/orbital_dynamics/timeline_test.exs`
- `test/orbital_dynamics/schema_test.exs`
- generated schemas that embed transition-application selected-integrity rows
- `docs/artifacts/field_families/mission_activities.md`

Likely tests:
- `mix test test/orbital_dynamics/timeline_test.exs:<transition integrity selectors>`
- `mix test test/orbital_dynamics/schema_test.exs:<transition schema selectors>`
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix orbital_dynamics.schema.lint --all`
- `git diff --check`

Definition of done:
- Selected-integrity transition evidence includes duplicate dependency,
  duplicate exclusivity, dependency cycle, dependency order, and exclusivity
  violation ID fields when present.
- Focused tests cover transition decision/application output for at least one
  non-missing dependency/exclusivity issue family.
- Public docs mention the richer selected-integrity evidence without claiming
  schedule mutation or operator authority.

Current implementation:
- `Timeline` now uses one selected-integrity context helper for direct
  lifecycle helper errors, transition decisions, and transition application
  rows.
- Selected-integrity evidence now lifts duplicate dependency/exclusivity,
  dependency cycle, dependency order, and exclusivity violation ID sets.
- Runtime schema validation and exported schemas recognize those selected ID
  fields in transition application rows and nested review/import handoffs.
- Operator-review and Cadence-import transition handoff rows copy the expanded
  selected-integrity ID fields at the top level as well as in the nested source
  transition application.
- Tests cover duplicate exclusivity selected-integrity evidence through direct
  helpers, transition reports, operator review, Cadence import, and schema
  export assertions.
- Mission-activities docs describe the richer selected-integrity evidence while
  preserving the artifact-only boundary.

Verification:
- `mix format lib/orbital_dynamics/timeline.ex lib/orbital_dynamics/schema.ex test/orbital_dynamics/timeline_test.exs`
- `mix format lib/orbital_dynamics/operator_review.ex lib/orbital_dynamics/cadence_import.ex test/orbital_dynamics/timeline_test.exs`
- `mix format test/orbital_dynamics/schema_test.exs`
- `mix test test/orbital_dynamics/timeline_test.exs:6781 test/orbital_dynamics/timeline_test.exs:8430`
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix orbital_dynamics.schema.lint --all`
- `mix test test/orbital_dynamics/timeline_test.exs:6781 test/orbital_dynamics/timeline_test.exs:8430 test/orbital_dynamics/schema_test.exs:13602 test/orbital_dynamics/schema_test.exs:14096 test/orbital_dynamics/schema_test.exs:14449 test/orbital_dynamics/schema_test.exs:21321`
- `mix test test/orbital_dynamics/timeline_test.exs:6781 test/orbital_dynamics/timeline_test.exs:8588 test/orbital_dynamics/schema_test.exs:14660 test/orbital_dynamics/schema_test.exs:21335`
- `git diff --check`

Review:
- Initial read-only review found a failing duplicate-exclusivity fixture that
  exercised the review-only transition path instead of selected-activity
  gating. The fixture was moved to a protected-source preservation path, and
  top-level operator-review/Cadence-import field copying was fixed.
- Clean follow-up read-only review found no issues. It verified the prior
  fixture problem is fixed, top-level and nested review/import handoff fields
  are present, schema export/validation surfaces include the expanded selected
  fields, and the focused transition/schema tests plus schema lint pass.

Product commit:
- `feac470` (`Expand selected transition integrity evidence`)

Previous pushed slice:
Timeline preservation assumption schema pinning landed in product commit
`cc730fd` and final pushed ledger commit `32fddb8`, with local and
`origin/main` verified at `32fddb89cf4c8d6b182664988b00e376a0e21916`.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Blocked:
No.

# Autonomous Product Loop Status

Current slice:
Typed timeline and feedback handoffs preserve declared battery-energy generation
evidence.

Status:
Implementation, docs, schema validation, and checked-in schema export refresh
are complete. Focused verification passes, including the reviewer-requested
nested activity-context validation regression. Operational timeline activity
context, timeline-feedback rows, operator-review rows, Cadence-import rows, and
feedback-derived resource-margin maps now preserve non-negative
`battery_energy_generated_wh` evidence. Clean declared generated-energy aliases
such as `energy_generated_wh`, `estimated_energy_generated_wh`,
`estimated_battery_energy_generated_wh`, and `planned_energy_generated_wh` are
normalized before handoff. This remains artifact-only resource evidence; it does
not roll battery state, mutate schedules, approve imports, reserve resources, or
execute commands.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `docs/artifacts/field_families/mission_activities.md`
- `docs/feature_set/capability_map/08_mission_activities/partial-and-future.md`
- `lib/orbital_dynamics/timeline.ex`
- `lib/orbital_dynamics/timeline_feedback.ex`
- `lib/orbital_dynamics/operator_review.ex`
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/schema.ex`
- `schemas/*.schema.json` impacted by shared activity/timeline-feedback row
  schemas and `schemas/orbital_dynamics.schema_bundle.v1.json`
- `test/orbital_dynamics/timeline_test.exs`
- `test/orbital_dynamics/timeline_feedback_test.exs`
- `test/orbital_dynamics/schema_test.exs`
- `test/mix/tasks/orbital_dynamics.schema.export_test.exs`

Tests run:
- `mix format lib/orbital_dynamics/timeline.ex lib/orbital_dynamics/timeline_feedback.ex lib/orbital_dynamics/schema.ex test/orbital_dynamics/timeline_test.exs test/orbital_dynamics/timeline_feedback_test.exs test/orbital_dynamics/schema_test.exs test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix format lib/orbital_dynamics/operator_review.ex lib/orbital_dynamics/cadence_import.ex`
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix test test/orbital_dynamics/schema_test.exs:3972 test/orbital_dynamics/timeline_test.exs:4016 test/orbital_dynamics/timeline_test.exs:5281 test/orbital_dynamics/timeline_feedback_test.exs:183 test/orbital_dynamics/timeline_feedback_test.exs:1230 test/orbital_dynamics/schema_test.exs:17691 test/mix/tasks/orbital_dynamics.schema.export_test.exs:4628 test/orbital_dynamics/schema_test.exs:20060 --trace --seed 0`
- `git diff --check`

Docs/artifacts changed:
- Mission-activity artifact docs now state typed timeline activity contexts
  preserve generated battery-energy evidence and accepted aliases.
- Mission-activities partial/near-term docs now include generated-energy
  resource feedback preservation.
- Checked-in schema exports refreshed.

Last commit:
- Pending publish.

Next candidate:
After review and publish, re-read the guide/ledger/live worktree and continue
with the highest-priority unimplemented typed activity context or feedback
handoff field family before moving to lower-priority resource/quality slices.

Blocked:
No.

Notes:
Reviewer found the shared nested `activity_context` executable validator was
missing the generated-energy non-negative check; fixed in `schema.ex` and
covered with a Cadence-import nested-context regression.
Treat current files as authoritative and do not revert unrelated changes.
`.gitignore` has an unrelated pre-existing local scratch-ignore change and is
not part of this slice.

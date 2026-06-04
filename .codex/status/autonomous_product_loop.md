# Autonomous Product Loop Status

Current slice:
`candidate_rejection_report.v1` exposes row-derived candidate ID routing by
required operator action.

Status:
Implementation, focused verification, schema export refresh, and read-only
review are complete. Product commit, push, and final ledger publish update are
pending. `Timeline.candidate_rejection_report/2` now emits
`candidate_ids_by_required_operator_action` so review/import adapters can route
`review_candidate_rejection` work without scanning every row. Runtime schema
validation accepts only supported candidate-rejection action keys, validates
stable candidate IDs, and rejects stale maps that do not match report rows.

Files changed for this slice:
- `.codex/status/autonomous_product_loop.md`
- `docs/artifacts/field_families/mission_activities.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/timeline.ex`
- `schemas/candidate_refresh.v1.schema.json`
- `schemas/candidate_rejection_report.v1.schema.json`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `test/orbital_dynamics/schema_test.exs`
- `test/orbital_dynamics/timeline_test.exs`

Tests run:
- `mix test test/orbital_dynamics/timeline_test.exs:7 test/orbital_dynamics/timeline_test.exs:7570 test/orbital_dynamics/schema_test.exs:12652 test/mix/tasks/orbital_dynamics.schema.export_test.exs:39 test/orbital_dynamics/schema_test.exs:19804 --trace --seed 0`
  passed capabilities, generated candidate-rejection report, standalone
  candidate-rejection schema validation, schema bundle export, and checked-in
  schema export drift coverage.

Docs/artifacts changed:
- `docs/artifacts/field_families/mission_activities.md` now documents the
  action-keyed candidate ID map and preserves the no-approval/no-import
  boundary.
- Checked-in JSON schema exports were refreshed with
  `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`.

Review:
- `slice_reviewer` reported no findings and recommended publishing after this
  ledger review update.

Last product commit:
- Pending.

Next candidate:
After publish, re-read `docs/autonomous_work_guide.md`, this ledger, and the
live worktree before choosing another gap. Continue with the highest-priority
unimplemented typed timeline/activity semantics before returning to resource/
communications replay helpers.

Blocked:
No.

Notes:
This slice intentionally does not select candidates, approve rejected
candidates, mutate schedules, import to Cadence, or execute commands. Treat
current files as authoritative and do not revert unrelated changes. `.gitignore`
has an unrelated pre-existing local scratch-ignore change and is not part of
this slice.

# Autonomous Product Loop Status

Current slice:
Make CandidateRefresh command-window source-report direction routing schema-visible.

Status:
Implemented, locally verified, reviewed clean, committed, and pushed. Runtime
CandidateRefresh command-window source summaries already preserve
command-feedback counts, input keys, direction counts, activity IDs by
direction, window IDs by direction, direction routing with activity counts and
activity/window IDs, and required-operator-action counts. The
`candidate_refresh.v1` family-specific source-report JSON Schema now advertises
those command-window fields. This is a contract discoverability slice only: no
replay behavior, runtime validation helpers, artifact generation logic, or
operator/Cadence authority behavior changed.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/schema.ex`
- `schemas/candidate_refresh.v1.schema.json`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `test/mix/tasks/orbital_dynamics.schema.export_test.exs`

Definition of done:
- `candidate_refresh.v1` exposes a family-specific `command_window_report`
  source-report schema.
- Its source-report object advertises command-feedback counts, input keys,
  direction count maps, activity/window ID maps by direction, direction routing
  with activity counts and activity/window IDs, and required-operator-action
  counts.
- Checked-in `candidate_refresh.v1` schema and schema bundle are refreshed.
- Schema export tests, schema tests, schema lint, and whitespace checks pass.

Tests run:
- `mix format lib/orbital_dynamics/schema.ex test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix test test/orbital_dynamics/schema_test.exs`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix orbital_dynamics.schema.lint --all`
- `jq` spot-checks for `command_window_report` in
  `schemas/candidate_refresh.v1.schema.json` and the schema bundle.
- `git diff --check`
- `slice_reviewer`: no must-fix findings; reran focused export test,
  whitespace check, and generated-schema `jq` spot-checks.
- `git_slice_publisher`: committed and pushed.

Last completed implementation commit:
`e2dfc848d06542978774f0f326c866e6e9ca46b7` pushed to `origin/main`.

Last ledger correction commit:
Pending for this slice.

Next candidate:
After this slice, evaluate timeline activity state action routing from the
mapper result.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.

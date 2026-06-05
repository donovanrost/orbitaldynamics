# Autonomous Product Loop Status

Current slice:
Make CandidateRefresh resource-projection source/station routing maps schema-visible.

Status:
Implemented, locally verified, and reviewed clean; commit/push pending.
Runtime CandidateRefresh resource-projection replay summaries already preserve
source-window and station-calendar routing maps by status/type, but the nested
`candidate_refresh.v1` source-report JSON Schema does not advertise those
fields. This is a contract discoverability slice only: no replay behavior,
runtime validation helpers, artifact generation logic, or operator/Cadence
authority behavior changed.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/schema.ex`
- `schemas/candidate_refresh.v1.schema.json`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `test/mix/tasks/orbital_dynamics.schema.export_test.exs`

Definition of done:
- Nested `candidate_refresh.v1` source-report JSON Schema explicitly includes
  source-window ID routing maps and station-calendar entry/provider/provider-entry
  ID routing maps by status/type.
- Export tests assert stable-ID-array-map shapes for those nested fields.
- Checked-in `candidate_refresh.v1` schema and schema bundle are refreshed.
- Schema export tests, schema tests, schema lint, and whitespace checks pass.

Tests run:
- `mix format lib/orbital_dynamics/schema.ex test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix test test/orbital_dynamics/schema_test.exs`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix orbital_dynamics.schema.lint --all`
- `git diff --check`
- `slice_reviewer`: no must-fix findings.
- `git_slice_publisher`: pending.

Last completed implementation commit:
`d7782fc54127d70e0acdbf7235f37195b57bd1cd` pushed to `origin/main`.

Last ledger correction commit:
`eb136f3e13433e49516759b0e8a75c2f4b57c95b` pushed to `origin/main`.

Next candidate:
Rerun the mapper against the current checkout.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.

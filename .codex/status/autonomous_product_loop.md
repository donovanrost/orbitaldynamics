# Autonomous Product Loop Status

Current slice:
Make CandidateRefresh resource-filter source-report direction routing schema-visible.

Status:
Implemented, locally verified, and reviewed clean; publish pending. Runtime
CandidateRefresh resource-filter source summaries already preserve suppressed
candidate counts, invalid resource-summary inputs, suppressed-reason maps,
spacecraft/resource/blocking-dimension maps, directions, candidate IDs by
direction, and direction routing with candidate counts and candidate IDs. The
`candidate_refresh.v1` family-specific source-report JSON Schema now advertises
those resource-filter fields. This is a contract discoverability slice only: no
replay behavior, runtime validation helpers, artifact generation logic, or
operator/Cadence authority behavior changed.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/schema.ex`
- `schemas/candidate_refresh.v1.schema.json`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `test/mix/tasks/orbital_dynamics.schema.export_test.exs`

Definition of done:
- `candidate_refresh.v1` exposes a family-specific `resource_filter_report`
  source-report schema.
- Its source-report object advertises resource-filter suppressed counts,
  invalid resource-summary input IDs, suppressed-reason maps,
  spacecraft/resource/blocking-dimension maps, directions, candidate IDs by
  direction, and direction routing with candidate counts and candidate IDs.
- Checked-in `candidate_refresh.v1` schema and schema bundle are refreshed.
- Schema export tests, schema tests, schema lint, and whitespace checks pass.

Tests run:
- `mix format lib/orbital_dynamics/schema.ex test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix test test/orbital_dynamics/schema_test.exs`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix orbital_dynamics.schema.lint --all`
- `jq` spot-checks for `resource_filter_report` in
  `schemas/candidate_refresh.v1.schema.json` and the schema bundle.
- `git diff --check`
- `slice_reviewer`: no must-fix findings; reran focused export test,
  whitespace check, and generated-schema `jq` spot-checks.

Last completed implementation commit:
Pending for this slice.

Last ledger correction commit:
Pending for this slice.

Next candidate:
After this slice, re-run a bounded mapper pass to find the next
schema-visible CandidateRefresh source-report routing gap.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.

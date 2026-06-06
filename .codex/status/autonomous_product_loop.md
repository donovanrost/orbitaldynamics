# Autonomous Product Loop Status

Current slice:
Expose CandidateRefresh operational-timeline source-report schema property.

Status:
Implemented, locally verified, and reviewed clean; publish pending. Runtime
CandidateRefresh operational-timeline source summaries already preserve input
keys, feedback counts, operational/activity status and approval count maps,
required-operator-action count maps, Cadence import status count maps, integrity
issue counts, and station-reservation evidence row counts. Replay helpers
already consume `operational_timeline_report` from source-report provenance. The
`candidate_refresh.v1` source-report JSON Schema now names
`operational_timeline_report` as a family-specific source report instead of
leaving it discoverable only through the generic `source_reports`
`additionalProperties` shape. This is a contract discoverability slice only: no
replay behavior, artifact generation logic, or operator/Cadence authority
behavior changed.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/schema.ex`
- `schemas/candidate_refresh.v1.schema.json`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `test/orbital_dynamics/schema_test.exs`

Definition of done:
- `candidate_refresh.v1` exposes a family-specific `operational_timeline_report`
  source-report schema.
- Its source-report object advertises input keys, feedback counts,
  operational-kind counts, activity/status/approval count maps,
  required-operator-action counts, Cadence import status counts, integrity issue
  counts, and station-reservation evidence row counts.
- Schema validation rejects obvious invalid operational-timeline list/count-map
  and integer-count shapes.
- Checked-in `candidate_refresh.v1` schema and schema bundle are refreshed.
- Schema export tests, schema tests, focused CandidateRefresh runtime tests,
  schema lint, generated-schema spot-checks, and whitespace checks pass.

Tests run:
- `mix format lib/orbital_dynamics/schema.ex test/mix/tasks/orbital_dynamics.schema.export_test.exs test/orbital_dynamics/schema_test.exs`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix test test/orbital_dynamics/schema_test.exs` (initially failed on stale
  checked-in schema export after validation passed; passed after export refresh)
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix test test/orbital_dynamics/schema_test.exs`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs --only line:32944`
- `mix orbital_dynamics.schema.lint --all`
- `jq` spot-checks for `operational_timeline_report` source-report fields in
  `schemas/candidate_refresh.v1.schema.json` and the schema bundle.
- `git diff --check -- . ':!.gitignore'`
- `slice_reviewer`: no must-fix findings; reran focused export test, schema
  test, focused CandidateRefresh runtime test, schema lint, whitespace check,
  and generated-schema `jq` spot-checks.

Last completed implementation commit:
Pending for this slice.

Last ledger correction commit:
Pending for this slice.

Next candidate:
After this slice, run a bounded mapper pass to identify the next
schema-visible CandidateRefresh source-report gap.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.

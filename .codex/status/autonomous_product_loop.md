# Autonomous Product Loop Status

Current slice:
Expose CandidateRefresh refresh-budget source-report schema property.

Status:
Implemented, locally verified, and reviewed clean. Runtime CandidateRefresh
source-report provenance already emits `refresh_budget_report` summaries for
artifact-only budget replay, including candidate input/kept/dropped counts,
invalid limit-policy evidence, candidate id sets, and trust-boundary metadata.
This slice makes that emitted family schema-visible under `candidate_refresh.v1`
`provenance.source_reports.properties` instead of relying only on the generic
`additionalProperties` summary schema, and adds executable validation for those
named summary fields. Runtime behavior, candidate generation, budget selection
policy, operator authority, import approval, and Cadence write behavior are
intentionally out of scope.

Files expected:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/schema.ex`
- `schemas/candidate_refresh.v1.schema.json`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `test/orbital_dynamics/schema_test.exs`

Definition of done:
- `candidate_refresh.v1` exposes a family-specific `refresh_budget_report`
  source-report schema.
- Its source-report object advertises refresh-budget candidate counts, invalid
  limit-policy reason counts, kept/dropped candidate ids, and trust-boundary
  metadata.
- Schema validation rejects obvious invalid refresh-budget count-map and
  candidate-id shapes at the named source-report path.
- Checked-in `candidate_refresh.v1` schema and schema bundle are refreshed.
- Schema export tests, schema tests, focused CandidateRefresh runtime tests,
  schema lint, generated-schema spot-checks, and whitespace checks pass.
- Read-only review finds no must-fix issues.
- Slice-owned files only are committed and pushed.

Tests run:
- `mix format lib/orbital_dynamics/schema.ex test/mix/tasks/orbital_dynamics.schema.export_test.exs test/orbital_dynamics/schema_test.exs`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix test test/orbital_dynamics/schema_test.exs:19554 test/orbital_dynamics/schema_test.exs:19640`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:25990`
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix test test/orbital_dynamics/schema_test.exs` (initially caught missing
  executable validation for named refresh-budget source-report fields; passed
  after adding the validator hook)
- `mix test test/orbital_dynamics/schema_test.exs:19693`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:25990`
- `mix test test/orbital_dynamics/schema_test.exs`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix orbital_dynamics.schema.lint --all`
- `jq` spot-checks for `refresh_budget_report` source-report fields in
  `schemas/candidate_refresh.v1.schema.json` and the schema bundle.
- `git diff --check -- . ':!.gitignore'`
- `slice_reviewer`: no must-fix findings. Residual risk noted that the named
  helper reuses the passive replay context helper and therefore advertises some
  optional passive-context fields not emitted by refresh-budget summaries; this
  follows the existing optional-helper pattern and is not a blocker.

Last completed implementation commit:
`a9c1f149b917681b63d51d9692a480744a695336` pushed to `origin/main`.

Last ledger correction commit:
`0365330` pushed to `origin/main`.

Next candidate:
After this slice, continue the CandidateRefresh source-report schema visibility
burn-down, likely with `freshness_report` or the objective/score report family.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.

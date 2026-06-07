# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Link-capacity report optional-field validity and fixture coverage.

Status:
Implemented, verified, and reviewed; ready for commit/push.

Files expected:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/communications/link_capacity.ex`
- `test/orbital_dynamics/communications/link_capacity_test.exs`
- `test/orbital_dynamics/schema_test.exs`
- `docs/artifacts/compatibility_checks.md`
- `study_results/link_capacity_report_v1.json`

Slice-selection note:
Selected after contact allocation capacity-pack fixture coverage was pushed at
`ff1aa7f7b56ec893e6c57da1b7d0c465ba4489b3` and live reassessment stayed in the
guide's resource and communications allocation queue. A no-edit probe showed
`OrbitalDynamics.link_capacity_report/3` emits present-but-`nil` optional
requirement, actual-throughput, completion, reservation-match, and derivation
fields for a simple fixed-rate downlink report with no explicit downlink
requirement or realized selected contact. The generated artifact fails
`link_capacity_report.v1` validation even though the checked-in full report
fixture validates by omitting those absent optional fields. This is a narrow
public-facade contract fix plus fixture coverage slice; it does not model link
budgets, reserve provider time, write Cadence, import artifacts, execute
commands, or mutate schedules.

Definition of done:
- Make `OrbitalDynamics.link_capacity_report/3` and `LinkCapacity.report/3`
  produce schema-valid `link_capacity_report.v1` output when optional downlink
  requirement, realized throughput/completion, reservation-match, or derivation
  evidence is absent.
- Add focused communications coverage proving the public facade output validates
  for the no-requirement/no-realized-data case.
- Add focused schema coverage proving `study_results/link_capacity_report_v1.json`
  exact-regenerates through the public facade from deterministic fixed-rate
  contact input, then validates.
- Refresh the checked-in full link-capacity fixture if current runtime output
  adds valid optional counters or assumptions, preserving fixed-rate
  capacity-adjusted throughput math and artifact-only no-link-budget/no-provider-
  reservation/no-schedule-mutation boundaries.
- Update compatibility docs to name the facade validity fix and exact full
  report regeneration check.
- Run focused link-capacity/schema tests, schema lint for the refreshed fixture,
  read-only review, and commit/push only this slice's files.

Implementation notes:
- Applied the existing link-capacity row compaction behavior to the top-level
  `link_capacity_report.v1` map so absent optional requirement,
  actual-throughput, completion, reservation-match, and derivation fields are
  omitted instead of emitted as present `nil` values.
- Refreshed `study_results/link_capacity_report_v1.json` mechanically from
  public `OrbitalDynamics.link_capacity_report/3` output using one
  deterministic fixed-rate downlink contact with declared station capacity.
- Added focused communications coverage proving public facade output validates
  for a no-requirement/no-realized-data report and contains no top-level nil
  optional values.
- Added focused schema-test coverage that exact-compares the checked-in full
  link-capacity fixture against public-facade output before schema validation,
  pinning fixed-rate capacity-adjusted throughput math, current optional
  counters, station capacity evidence, model limits, and artifact-only
  no-link-budget/no-provider-reservation/no-schedule-mutation assumptions.
- Updated compatibility docs to name the facade validity fix and exact full
  report regeneration check.

Verification:
- `mix format lib/orbital_dynamics/communications/link_capacity.ex test/orbital_dynamics/communications/link_capacity_test.exs test/orbital_dynamics/schema_test.exs`
- `mix test test/orbital_dynamics/communications/link_capacity_test.exs:4466`
- `mix test test/orbital_dynamics/schema_test.exs:3644`
- `mix test test/orbital_dynamics/schema_test.exs:3728`
- `mix test test/orbital_dynamics/schema_test.exs:29137`
- `mix orbital_dynamics.schema.lint --input study_results/link_capacity_report_v1.json --contract link_capacity_report.v1`
- `mix orbital_dynamics.schema.lint --all`
- `git diff --check -- .codex/status/autonomous_product_loop.md docs/artifacts/compatibility_checks.md lib/orbital_dynamics/communications/link_capacity.ex study_results/link_capacity_report_v1.json test/orbital_dynamics/communications/link_capacity_test.exs test/orbital_dynamics/schema_test.exs`

Review:
- Read-only review sidecar `019ea23a-795c-7671-9b8b-fa82663f1f57` found no
  correctness issues. It confirmed top-level `compact_map/1` removes invalid
  present-`nil` optional fields while required report fields remain populated,
  and that the public facade and checked-in full fixture tests cover the
  no-requirement/no-realized-data case.
- The reviewer noted a low docs improvement: the link-capacity compatibility
  paragraph did not explicitly carry the no-Cadence-write boundary. Fixed by
  adding artifact-only no-link-budget/no-provider-reservation/no-schedule-
  mutation/no-Cadence-write wording to the paragraph.
- The reviewer also noted the publish risk that unrelated `.gitignore` remains
  dirty; staging for this slice stays path-scoped and excludes `.gitignore`.

Last commit:
`ff1aa7f7b56ec893e6c57da1b7d0c465ba4489b3` pushed to `origin/main` for contact
allocation capacity-pack report fixture coverage.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Blocked:
No.

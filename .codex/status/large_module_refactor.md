# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Study Manifest activity-input extraction.

Status:
Completed and pushed in `edd99630`.

Selected boundary:
Extract activity-list parsing and construction, mission-plan activity scope
enforcement, activity option/evidence parsing, nested identity aliases,
contact-direction normalization, and the matching contact-direction schema
property into `OrbitalDynamics.Study.Manifest.ActivityInput`. Preserve
`OrbitalDynamics.Study.Manifest` as the public facade and retain private
delegates at its three existing call sites.

Selection evidence:
- Live re-ranking places `study/manifest.ex` at 3,000 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of StationCalendar,
  OrbitalDynamics, RecommendationRiskContext, OperationalReadiness,
  TimelineFeedback, ContactContention, LinkCapacity, and ResourceProjection.
- The selected block spans lines 1,746-2,511. It owns the activity array
  reducer, scenario/spacecraft scope validation, all supported activity
  constructors, the complete activity option/evidence field matrix, nested
  target/station/spacecraft/command-window identity resolution, legacy overlap
  handling, status/approval parsing, provider direction aliases, health-check
  direction validation, and the schema enum derived from the same capability
  catalog.
- The boundary has three facade consumers: mission-plan activity parsing,
  mission-plan scope application, and prior-candidate direction schema
  construction. Private facade delegates preserve those call sites while the
  owner holds one implementation.
- General manifest JSON decoding, validation reports, schema assembly,
  scenario/campaign/candidate-refresh parsing, spacecraft and maneuver input,
  run options, metadata outside activity options, and public input/output
  contracts remain outside this boundary.
- Existing first-error behavior, activity order, struct construction, option
  omission/defaults, identity precedence, direction aliases, schema ordering,
  and exact error tuples must remain unchanged.

Verification:
- Strict warning-clean compile passed across 3,948 files:
  `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force --warnings-as-errors`.
- Focused Study Manifest regression passed: 42 tests.
- Adjacent manifest lint, reference, schema-export, and validation-fixture
  regression bundle passed: 20 tests.
- Exact old/new parity passed 11 comparisons from selection commit `c864d294`
  with `/tmp/manifest_activity_input_compare.exs`, covering option-rich activity
  construction, JSON loading, JSON Schema and field-reference output,
  `activity_type` and nested identity aliases, provider directions, scope and
  overlap failures, health-check validation, invalid nested identities, and
  unsupported activity frames.
- `mix xref callers OrbitalDynamics.Study.Manifest.ActivityInput` reports only
  the Study Manifest facade.
- The owner has no compile-connected expansion beyond itself.
- Focused formatting, `git diff --check`, removed-helper static checks, and
  final facade/owner review passed.

Behavior/schema changes:
None. The public Study Manifest facade, manifest and activity input contracts,
JSON Schema and field-reference output, deterministic ordering, defaults,
identity precedence, and exact error tuples are unchanged.

Last completed slice:
Study Manifest activity-input extraction, selected in `c864d294` and
implemented in `edd99630`.
`study/manifest.ex` moved from 3,000 to 2,229 lines; the dedicated
activity-input owner is 826 lines.

Next candidate:
Re-rank the live largest-module inventory and select the next cohesive,
facade-preserving ownership boundary.

Blocked:
No.

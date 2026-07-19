# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Manifest ground-network input extraction.

Status:
Completed and pushed.

Selected boundary:
Extract campaign/candidate-refresh ground-network list parsing, station
identity aliases, availability/status normalization, interval validation, and
reservation/provider context projection into
`OrbitalDynamics.Study.Manifest.GroundNetworkInput`.
Preserve the existing Manifest public API facade.

Selection evidence:
- Live re-ranking places `study/manifest.ex` at 3,108 lines, fifth behind
  Schema, Timeline, MissionPlan.Activity, and LinkCapacity and ahead of
  ContactAllocation, TimelineFeedback, ContactContention, ResourceProjection,
  StationCalendar, RecommendationRiskContext, and OperationalReadiness.
- Higher-ranked LinkCapacity summary aggregation remains coupled to shared
  station-calendar normalization and reservation inference. The selected
  family is one shared normalization path used by campaign and
  candidate-refresh metadata parsing.
- Manifest schema generation, campaign/candidate-refresh metadata assembly,
  station catalogs, scenarios, activities, resource summaries, and run
  assembly remain outside this boundary.
- Existing list order, invalid-field paths, identity alias precedence,
  availability/status mapping, numeric capacity inference, nullable fields,
  interval rules, omission behavior, and deterministic output remain
  unchanged.

Verification:
- Focused baseline before implementation:
  `test/orbital_dynamics/study/manifest_test.exs` passed 42 tests.
- Strict compilation after implementation:
  `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force --warnings-as-errors`
  compiled 3,942 files successfully.
- Focused regression:
  `test/orbital_dynamics/study/manifest_test.exs` passed 42 tests.
- Adjacent regressions:
  `test/orbital_dynamics/validation/manifest_fixture_test.exs` passed 2 tests
  and `test/orbital_dynamics/cadence_import_test.exs` passed 72 tests.
- Exact old/new comparison against selection commit `fe2a7e97` exposed the
  selected list parser and campaign wrapper and compared 14 inputs; all 14
  outputs matched exactly.
- The exact inputs covered empty/full entries, station identity aliases,
  numeric and string availability, explicit status precedence, nullable
  fields, empty directions, invalid entry shapes, missing station identity,
  invalid availability and intervals, absent campaign input, and invalid
  campaign list shape.
- `git diff --check` passed.
- `mix xref callers OrbitalDynamics.Study.Manifest.GroundNetworkInput` reports
  only the Manifest facade as a runtime caller; compile-connected xref reports
  no unexpected coupling.
- Static review confirmed the owner exposes only `campaign/1` and `parse/2`;
  schema generation, metadata assembly, station catalogs, scenarios,
  activities, resource summaries, and run assembly remain outside the
  boundary.

Behavior/schema changes:
None. Existing ground-network normalization, validation errors, manifest
shape, schemas, and deterministic output are preserved.

Last completed slice:
Manifest ground-network input extraction, selected in `fe2a7e97` and
implemented in `f99a8866`.
`study/manifest.ex` moved from 3,108 to 3,000 lines; the dedicated
ground-network input owner is 117 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Manifest ground-station catalog input extraction.

Status:
Completed and pushed.

Selected boundary:
Extract direct ground-station catalog parsing, candidate-refresh mission-state
fallback, ground-network station normalization, stable-ID dedupe, and
GroundStation construction into
`OrbitalDynamics.Study.Manifest.GroundStationCatalogInput`.
Preserve the existing Manifest public API facade.

Selection evidence:
- Live re-ranking places `study/manifest.ex` at 3,234 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of
  OperationalReadiness, TimelineFeedback, ContactContention, LinkCapacity,
  RecommendationRiskContext, ContactAllocation, ResourceProjection, and
  StationCalendar.
- The selected family is one independent run-input catalog reached once from
  `from_map/1`; it owns source selection, coordinate-bearing station
  normalization, stable-ID dedupe, field validation, and GroundStation
  construction.
- Manifest schema generation, campaign ground-network metadata, candidate
  refresh metadata, target and crossing catalogs, scenario/activity parsing,
  and run assembly remain outside this boundary.
- Existing direct-catalog precedence, empty-list fallback, invalid-field paths,
  coordinate filtering, default minimum elevation, first-ID-wins order,
  constructor behavior, and deterministic output remain unchanged.

Verification:
- Focused baseline before implementation:
  `test/orbital_dynamics/study/manifest_test.exs` passed 42 tests.
- Strict compilation after implementation:
  `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force --warnings-as-errors`
  compiled 3,937 files successfully.
- Focused regression:
  `test/orbital_dynamics/study/manifest_test.exs` passed 42 tests.
- Adjacent regressions:
  `test/orbital_dynamics/validation/manifest_fixture_test.exs` passed 2 tests
  and `test/orbital_dynamics/cadence_import_test.exs` passed 72 tests.
- Exact old/new comparison against selection commit `03d2f023` exposed the
  selected private parser from the old facade and compared ten catalog inputs;
  all 10 outputs matched exactly.
- The exact inputs covered absent and direct catalogs, invalid catalog and
  station inputs, empty-list mission-state fallback, invalid mission state,
  ground-network coordinate filtering, catalog/network duplicate precedence,
  and partially invalid mission-state sources.
- `git diff --check` passed.
- `mix xref callers
  OrbitalDynamics.Study.Manifest.GroundStationCatalogInput` reports only the
  Manifest facade as a runtime caller; compile-connected xref reports no
  unexpected coupling.
- Static review confirmed the owner exposes only `parse/1`; schema generation,
  campaign and candidate-refresh metadata, target and crossing catalogs,
  scenario/activity parsing, and run assembly remain outside the boundary.

Behavior/schema changes:
None. Existing station source precedence and normalization, validation errors,
manifest shape, schema exports, and deterministic output are preserved.

Last completed slice:
Manifest ground-station catalog input extraction, selected in `03d2f023` and
implemented in `04338497`.
`study/manifest.ex` moved from 3,234 to 3,108 lines; the dedicated
ground-station catalog owner is 146 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.

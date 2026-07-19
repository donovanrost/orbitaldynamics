# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Manifest target-catalog input extraction.

Status:
Completed and pushed.

Selected boundary:
Extract campaign and candidate-refresh target-source precedence, mission-state
catalog/objective target synthesis, target normalization and stable
deduplication, field validation, and `Target` construction into
`OrbitalDynamics.Study.Manifest.TargetCatalogInput`.
Preserve the existing Manifest public API facade.

Selection evidence:
- Live re-ranking places `study/manifest.ex` at 3,357 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of StationCalendar,
  ContactAllocation, RecommendationRiskContext, TimelineFeedback,
  OperationalReadiness, ContactContention, LinkCapacity, and
  ResourceProjection.
- The selected family owns one manifest-intake responsibility used by
  `from_map/1`: resolving declared or mission-state-derived target specs into a
  deterministic validated target catalog.
- JSON schema generation, scenario/mission-plan/campaign parsing, ground
  stations, activities, candidate-refresh metadata, run options, and manifest
  artifact assembly remain outside this boundary.
- Existing campaign precedence, empty candidate-refresh fallback, invalid-field
  paths, objective target eligibility, catalog-before-objective ordering,
  first-ID-wins deduplication, defaults, and deterministic output remain
  unchanged.

Verification:
- Focused baseline before implementation:
  `test/orbital_dynamics/study/manifest_test.exs` passed 42 tests.
- Strict compilation after implementation:
  `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force --warnings-as-errors`
  compiled 3,932 files successfully.
- Focused regression:
  `test/orbital_dynamics/study/manifest_test.exs` passed 42 tests.
- Adjacent regressions:
  `test/orbital_dynamics/validation/manifest_fixture_test.exs` passed 2 tests,
  `test/orbital_dynamics/candidate_refresh/observation_objective_build_test.exs`
  passed 5 tests, and
  `test/mix/tasks/orbital_dynamics.manifest.lint_test.exs` passed 7 tests.
- Exact old/new comparison against selection commit `2769ef8f` covered eight
  target-source states; all 8 outputs matched exactly.
- The exact states covered no targets, empty campaign targets, populated and
  invalid campaign targets, direct candidate-refresh targets, empty-target
  mission-state fallback, duplicate target IDs, objective-derived targets, and
  invalid mission-state catalog/objective shapes.
- `git diff --check` passed.
- `mix xref callers
  OrbitalDynamics.Study.Manifest.TargetCatalogInput` reports only the Manifest
  facade as a runtime caller; compile-connected xref reports no unexpected
  coupling.
- Static review confirmed campaign precedence, invalid-field paths, defaults,
  ordering, and first-ID-wins semantics remain in the owner; the shared
  ground-station deduplication helper remains in the facade.

Behavior/schema changes:
None. Existing target-source precedence, mission-state fallback, validation,
normalization, deduplication, defaults, error tuples, and deterministic output
are preserved.

Last completed slice:
Manifest target-catalog input extraction, selected in `2769ef8f` and
implemented in `cc2431e8`.
`study/manifest.ex` moved from 3,357 to 3,234 lines; the dedicated
target-catalog input owner is 159 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.

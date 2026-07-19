# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
LinkCapacity station-capacity evidence extraction.

Status:
Completed and pushed.

Selected boundary:
Extract station-capacity fraction/percent path catalogs, capability metadata,
direct/source-calendar precedence, percent conversion, ambiguous-source
handling, and default fraction into
`OrbitalDynamics.Communications.LinkCapacity.StationCapacity`.
Preserve the existing LinkCapacity public API facade.

Selection evidence:
- Live re-ranking places `communications/link_capacity.ex` at 3,113 lines,
  fourth behind Schema, Timeline, and MissionPlan.Activity and ahead of
  Manifest, ContactAllocation, TimelineFeedback, ContactContention,
  ResourceProjection, StationCalendar, RecommendationRiskContext, and
  OperationalReadiness.
- The selected family is one closed evidence resolver used by throughput
  adjustment and station-availability classification and surfaced verbatim in
  capability/assumption metadata.
- Contact validation, throughput and completion derivation, station
  availability severity, report/summary assembly, downlink requirements,
  approval policy, and relay data paths remain outside this boundary.
- Existing ordered path precedence, numeric/string parsing, percent-to-fraction
  conversion, unique-source requirement, direct-before-source precedence,
  missing/ambiguous default of `1.0`, capability metadata, and deterministic
  output remain unchanged.

Verification:
- Focused baseline before implementation:
  `test/orbital_dynamics/communications/link_capacity_test.exs` passed 44 tests.
- Strict compilation after implementation:
  `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force --warnings-as-errors`
  compiled 3,943 files successfully.
- Focused regression:
  `test/orbital_dynamics/communications/link_capacity_test.exs` passed 44 tests.
- Adjacent regressions:
  `test/orbital_dynamics/operator_review/link_capacity_test.exs` passed 8 tests,
  `test/orbital_dynamics/validation/link_capacity_fixture_test.exs` passed
  3 tests, and
  `test/orbital_dynamics/campaign_planner/repair_link_capacity_requirements_test.exs`
  passed 3 tests.
- Exact old/new comparison against selection commit `df538ba1` exposed the
  selected private resolver and compared eleven contact/source states plus the
  public capacity capability catalog; all 12 outputs matched exactly.
- The exact inputs covered missing evidence, direct fraction/percent values,
  numeric strings, every nested model family, ordered direct precedence,
  unique duplicate source values, ambiguous source values, invalid direct
  values, source fallback, percent conversion, and default fraction.
- `git diff --check` passed.
- `mix xref callers
  OrbitalDynamics.Communications.LinkCapacity.StationCapacity` reports only
  the LinkCapacity facade as a runtime caller; compile-connected xref reports
  no unexpected coupling.
- Static review confirmed the owner exposes the path catalogs, metadata,
  assumptions, and `value/1`; contact validation, throughput/completion
  derivation, availability severity, report/summary assembly, approval policy,
  and relay data paths remain outside the boundary.

Behavior/schema changes:
None. Existing station-capacity precedence and normalization, throughput
behavior, capability metadata, schemas, and deterministic output are
preserved.

Last completed slice:
LinkCapacity station-capacity evidence extraction, selected in `df538ba1` and
implemented in `638f1592`.
`communications/link_capacity.ex` moved from 3,113 to 3,016 lines; the
dedicated station-capacity owner is 121 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.

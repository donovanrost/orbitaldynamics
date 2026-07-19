# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ResourceProjection resource-summary input extraction.

Status:
Completed and pushed.

Selected boundary:
Extract external resource-summary key/alias normalization, provenance and
availability normalization, numeric and battery-field derivation, stable
spacecraft identity and value validation, invalid-input row construction, and
duplicate/mixed-scope review gating into
`OrbitalDynamics.ResourceProjection.ResourceSummaryInput`.
Preserve the existing ResourceProjection public API facade.

Selection evidence:
- Live re-ranking places `resource_projection.ex` at 3,447 lines, fourth
  behind Schema, Timeline, and MissionPlan.Activity and ahead of Manifest,
  StationCalendar, ContactAllocation, RecommendationRiskContext,
  TimelineFeedback, OperationalReadiness, ContactContention, and LinkCapacity.
- The selected family owns one intake responsibility used by `report/3`:
  converting untrusted resource-summary inputs into deterministic valid rows or
  review-gated invalid rows before projection math begins.
- Activity input normalization, activity suppression checks, projection and
  roll-forward math, pressure/risk classification, approval policy, flow
  summaries, and artifact assembly remain outside this boundary.
- Existing alias precedence, numeric parsing, derived-margin tolerance,
  wildcard/duplicate scope rules, invalid-row identity, ordering, omission
  behavior, and deterministic output remain unchanged.

Verification:
- Focused baseline before implementation:
  `test/orbital_dynamics/resource_projection_test.exs` passed 49 tests.
- Strict compilation after implementation:
  `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force --warnings-as-errors`
  compiled 3,931 files successfully.
- Focused regression:
  `test/orbital_dynamics/resource_projection_test.exs` passed 49 tests.
- Adjacent downstream regressions:
  `test/orbital_dynamics/resource_filter_test.exs` passed 37 tests and
  `test/orbital_dynamics/operator_review/resource_projection_test.exs` passed
  5 tests.
- Exact old/new comparison against selection commit `73a15f12` covered six
  resource-summary sets across `report/3`, `flow_summary/1`, and
  `flow_report/1`; all 18 outputs matched exactly.
- The exact states covered canonical and aliased valid input, provenance and
  availability aliases, numeric and battery derivation, invalid shapes and
  negative values, stale derived margins, duplicate scopes, mixed wildcard
  scopes, nested spacecraft identity, and activity-type list normalization.
- `git diff --check` passed.
- `mix xref callers
  OrbitalDynamics.ResourceProjection.ResourceSummaryInput` reports only the
  ResourceProjection facade as a runtime caller; compile-connected xref reports
  no unexpected coupling.
- Static review confirmed the owner exposes only `normalize/1`; activity input
  handling, shared activity/provider token helpers, projection math,
  pressure/risk policy, flow summaries, and public APIs remain in the facade.

Behavior/schema changes:
None. Existing input ordering, alias precedence, value validation,
derived-margin tolerance, invalid-row identities, duplicate/wildcard review
gating, omission behavior, artifact shape, and deterministic output are
preserved.

Last completed slice:
ResourceProjection resource-summary input extraction, selected in `73a15f12`
and implemented in `d61339d3`.
`resource_projection.ex` moved from 3,447 to 3,010 lines; the dedicated
resource-summary input owner is 611 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.

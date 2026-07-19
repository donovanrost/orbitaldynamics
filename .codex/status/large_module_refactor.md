# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OrbitalDynamics activity-template catalog extraction.

Status:
Completed and pushed in `c122fda2`.

Selected boundary:
Extract the baseline activity-template specifications, catalog capabilities,
artifact construction, lookup, override validation, normalized activity
instantiation, and template provenance into
`OrbitalDynamics.ActivityTemplateCatalog`.
Preserve the existing `OrbitalDynamics` public API facade.

Selection evidence:
- Live re-ranking places `orbital_dynamics.ex` at 3,572 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of Manifest,
  LinkCapacity, StationCalendar, TimelineFeedback, ResourceProjection,
  ContactAllocation, and RecommendationRiskContext.
- The selected family is the root facade's only substantial private domain
  responsibility: owning the reusable baseline planning activity-template
  catalog and converting templates into normalized timeline activities.
- Capability catalog assembly and all propagation, planning, operations,
  review, import, readiness, validation, and reporting facades remain outside
  this boundary.
- Existing template vocabulary and ordering, lookup behavior, validation/error
  shapes, lifecycle/default merge precedence, provenance, normalization, and
  public return values remain unchanged.

Verification:
- Strict test-environment compile passed with warnings as errors across 3,926
  files.
- Focused public capability/catalog coverage passed: 6 tests.
- Adjacent activity-template fixture and mission-plan coverage passed: 35
  tests.
- Exact public old/new comparison against selection commit `599aa35d` passed
  for all six template artifacts, twelve id/type lookups, seven successful
  instantiations, five error cases, and the planning capability-catalog entry.
- `mix xref callers` reports only the `OrbitalDynamics` facade as a runtime
  caller of the extracted activity-template catalog.
- Static ownership checks confirm template specifications, artifact
  construction, lookup, override/required-field validation, normalized
  instantiation, and provenance live in the dedicated owner while the root
  public API retains its three documented facade functions.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
OrbitalDynamics activity-template catalog extraction, selected in `599aa35d`
and implemented in `c122fda2`.
`orbital_dynamics.ex` moved from 3,572 to 2,951 lines; the dedicated
activity-template catalog owner is 646 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.

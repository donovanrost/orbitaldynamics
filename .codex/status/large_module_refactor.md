# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Manifest target-catalog input extraction.

Status:
Selected; implementation pending.

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
Pending.

Behavior/schema changes:
None intended. This is a facade-preserving production ownership extraction.

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

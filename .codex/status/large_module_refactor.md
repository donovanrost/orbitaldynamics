# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactContention contact-normalization extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract recursive key/string conversion, numeric parsing, contact shape,
station identity, timing/numeric fields, station-calendar status trees,
activity type/direction aliases, compact-map behavior, and deterministic value
encoding into
`OrbitalDynamics.Communications.ContactContention.ContactNormalization`.
Preserve narrow private facade delegates and the existing public API.

Selection evidence:
- Live re-ranking places `communications/contact_contention.ex` at 3,035
  lines,
  fourth behind Schema, Timeline, and MissionPlan.Activity and ahead of
  LinkCapacity, ResourceProjection, Manifest, StationCalendar,
  OrbitalDynamics, RecommendationRiskContext, OperationalReadiness,
  TimelineFeedback, and ContactAllocation.
- The selected terminal family occupies the facade's final normalization block
  from numeric parsing through contact normalization, with recursive status
  normalization and value encoding used consistently by annotation, report,
  resolution, policy, evidence, and sorting paths.
- The owner can expose eight narrow functions while receiving the three
  policy catalogs that differ by caller: unavailable aliases, default priority
  fields, and provider direction aliases. Existing facade call sites remain
  unchanged behind private delegates.
- Contention grouping, timing metrics, resolution summaries, capacity and
  station evidence, feedback aggregation, approval policy, resolution policy,
  identity validation, throughput derivation, report contracts, and public
  clauses remain outside this boundary.
- Existing recursive key conversion, atom/boolean handling, numeric-string
  parsing, station identity precedence, canonical time precedence, status
  aliasing, nested station-calendar recursion, numeric priority normalization,
  type/direction inference, float encoding, nil omission, and deterministic
  output must remain unchanged.

Verification:
Pending implementation.

Behavior/schema changes:
None intended.

Last completed slice:
TimelineFeedback operational-context extraction, selected in `933df86b` and
implemented in `88f7271c`.
`timeline_feedback.ex` moved from 3,061 to 2,809 lines; the dedicated
operational-context owner is 295 lines.

Next candidate:
Implement and verify the selected ContactContention contact-normalization
extraction.

Blocked:
No.

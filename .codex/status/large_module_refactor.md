# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Study Manifest activity-input extraction.

Status:
Selected; implementation not started.

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
Pending implementation.

Behavior/schema changes:
None intended.

Last completed slice:
ResourceProjection flow-summary extraction, selected in `692d755f` and
implemented in `2e1f6682`.
`resource_projection.ex` moved from 3,010 to 2,504 lines; the dedicated
flow-summary owner is 562 lines.

Next candidate:
Implement and verify the selected Study Manifest activity-input extraction.

Blocked:
No.

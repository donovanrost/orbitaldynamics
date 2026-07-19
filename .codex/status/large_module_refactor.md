# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
LinkCapacity contact-normalization extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract recursive key/string conversion, numeric parsing, contact shape,
station identity, timing fields, station-calendar status/direction trees,
activity type aliases, nested throughput-model normalization, and compact-map
behavior into
`OrbitalDynamics.Communications.LinkCapacity.ContactNormalization`.
Preserve narrow private facade delegates and the existing public API.

Selection evidence:
- Live re-ranking places `communications/link_capacity.ex` at 3,016 lines,
  fourth behind Schema, Timeline, and MissionPlan.Activity and ahead of
  ResourceProjection, Manifest, StationCalendar, OrbitalDynamics,
  RecommendationRiskContext, OperationalReadiness, TimelineFeedback,
  ContactContention, and ContactAllocation.
- The selected terminal family occupies lines 2,780-3,015 and is the single
  normalization path used before link-capacity validation, grouping,
  throughput, and summary assembly.
- Numeric parsing is also used by throughput, completion, policy, and summary
  helpers, so the new owner exposes it through the existing facade helper;
  recursive status/direction and throughput-model helpers remain private to
  the owner.
- Report/summary aggregation, station-capacity evidence, contact feedback and
  identity, relay paths, input validation, throughput/completion derivation,
  downlink policy, approval policy, station availability, contracts, and
  public clauses remain outside this boundary.
- Existing recursive key conversion, atom/boolean handling, numeric-string
  parsing, station identity precedence, canonical time precedence, unavailable
  aliases, status/direction normalization, direction-list cleanup, nested
  station-calendar recursion, type inference, throughput-model shape handling,
  nil omission, and deterministic output must remain unchanged.

Verification:
Pending implementation.

Behavior/schema changes:
None intended.

Last completed slice:
ContactContention contact-normalization extraction, selected in `16aa47c2`
and implemented in `8206862c`.
`communications/contact_contention.ex` moved from 3,035 to 2,805 lines; the
dedicated contact-normalization owner is 275 lines.

Next candidate:
Implement and verify the selected LinkCapacity contact-normalization
extraction.

Blocked:
No.

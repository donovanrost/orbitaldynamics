# What-If Event Types

Supported what-if event types in the current V3 slice:

- `ground_station_outage`: marks affected selected downlinks missed and removes
  outage-overlapping downlink candidates before V2 repair. When V3 derives a
  branch refresh from mission-state inputs, the outage is also overlaid into the
  generated refresh `ground_network` so `contact_filter_report.v1` records the
  suppressed downlink opportunities, including station-calendar provider ID,
  provider entry ID, direction scope, status, and trust-boundary provenance when
  the outage came from a `station_calendar_provider.v1` input.
- `ground_station_reserved`: treats declared station reservations as
  unavailable for overlapping downlink opportunities. Derived branch refreshes
  copy reservation ID, owner, reservation status, and provider-calendar identity
  into the generated `ground_network` entry so suppressed contact-filter rows
  preserve the reservation context.
- `urgent_target`: stages a high-priority observation as a strategic addition
  requiring approval.
- `degraded_spacecraft`: injects degraded spacecraft state so V2 suppresses
  incompatible payload activities. When V3 derives a branch refresh, the same
  event overlays a thin `resource_summary.v1` row so
  `resource_filter_report.v1` records suppressed observation or contact
  opportunities using availability and margin-threshold policy checks.
- `resource_margin_pressure`: carries a deterministic low-resource branch
  assumption, currently for low `fuel_margin`, `power_margin`,
  `storage_margin`, or `downlink_margin`. When V3 derives a branch refresh, the
  event overlays `resource_summary.v1` so the same `resource_filter_report.v1`
  policy can suppress candidates without claiming a calibrated fuel, power,
  storage, or link-budget simulation.
  The same thin filtering behavior is available through
  `OrbitalDynamics.ResourceFilter` and the public
  `OrbitalDynamics.filter_resource_candidates/3` and
  `OrbitalDynamics.resource_filter_report/3` facades for standalone candidate
  lists. Suppressed contact and resource rows become typed Cadence import
  adapter gates that preserve source suppression context, policy evidence,
  station reservation metadata, duplicate suppressed-candidate identity
  metadata, and thin resource availability fields for operator review.
- Standalone contact filtering is available through
  `OrbitalDynamics.Communications.ContactFilter` and the public
  `OrbitalDynamics.filter_contact_candidates/3` and
  `OrbitalDynamics.contact_filter_report/3` facades. It applies the same
  artifact-only ground-network availability model used by candidate refresh:
  declared unavailable, reserved, or zero-capacity station windows can suppress
  typed or direction-only downlink candidates, and callers may pass either
  normalized ground-network rows or a `station_calendar_provider.v1` object, but
  the API does not reserve provider capacity or mutate schedules. Malformed downlink/tracking-like inputs
  missing identity, station, or timing fields become invalid-input
  review rows instead of kept candidates. Duplicate suppressed contact IDs are
  preserved with deterministic suffixed row IDs. Contact contention and allocation
  likewise accept direction-only command, uplink, tracking, and downlink station
  rows so Cadence-facing adapter payloads do not need synthetic activity types
  before review. Contact-intent, station-calendar, contact-contention, and
  contact-allocation approval requirements classify uplink contacts as
  command-review authority boundaries, with contention recommendations
  preserving direction evidence into review/import rows. Allocation blocks any
  contact direction when the declared station overlay is unavailable,
  maintenance, or zero-capacity, while reserved or reduced-capacity station
  overlaps remain explicit review/policy boundaries.
- `resource_availability_constraint`: carries a deterministic unavailable
  resource branch assumption, currently for `payload_available: false` or
  `antenna_available: false`. When V3 derives a branch refresh, the event
  overlays `resource_summary.v1` so generated observation or downlink
  candidates are suppressed through the existing resource filter instead of a
  live payload or antenna allocation model.
- `missed_maneuver` and `delayed_maneuver`: add realized maneuver outcomes and
  preserve V2 downstream repair behavior where applicable. When V3 derives a
  branch refresh, these events are also recorded as
  `maneuver_execution_delta` rows on the generated accepted planning state so
  candidate-source metadata shows the branch's maneuver-execution assumptions.
- `reduced_downlink_capacity`: records capacity adjustment and scales matching
  downlink candidate value. Derived branch refreshes also pass station capacity
  into `ground_network` so refreshed contact candidates carry the reduced
  throughput assumptions.
- `downlink_completion_gap`: stages non-overlapping generated downlink
  candidates as approval-required strategic additions when an explicit
  downlink-completion objective requires more contacts or more downlink data
  volume than the branch already effectively carries after realized
  missed/failed contacts. Explicit collection/product/payload/instrument
  selectors on the objective are preserved on the event and are matched against
  planned and candidate downlinks so unrelated data products do not satisfy or
  repair the gap. Branch objective-satisfaction and branch-comparison evidence
  aggregate multiple downlink-completion objectives at the objective-ratio
  level, so one satisfied scoped objective does not mask a second unsatisfied
  scoped objective; when one objective declares both required contacts and
  required downlink volume, both dimensions must be met before that objective is
  treated as complete, and branch risk text preserves both shortfalls when both
  dimensions are unmet. Explicit branch `downlink_completion_gap` events that
  do not carry their own `required_downlink_mb` inherit aggregate mission-state
  downlink volume demand. A `collection_latency` objective can derive the same
  event and branch-generated refresh from accepted mission state for each
  observation that lacks an on-time follow-on downlink inside the required
  latency window or lacks enough required downlink data volume inside that
  window, excluding realized missed/failed downlinks from the latency and volume
  check. Collection-latency events preserve the triggering objective ID and use
  it in derived branch IDs when present, preserve collection/product/payload/
  instrument selectors from the objective or triggering observation, and scope
  branch derivation to matching observations and matching explicitly identified
  planned or realized downlinks, so separate latency objectives on the same
  observation remain distinct. V3 pressure replay also accepts nested source
  observation/activity station, scenario, and planned downlink-volume metadata
  when deriving objective-satisfaction and objective-tradeoff collection-latency
  branches, and accepts nested target/scenario/source-activity evidence when
  deriving coverage or target-gap urgent-target branches. Score-term-derived
  collection-latency and urgent-target branches use the same nested
  source-observation/source-activity routing model for station, scenario,
  selectors, data-volume evidence, and target geometry. V3 branch
  `objective_satisfaction` rows summarize collection-latency
  status per observation, including planned latency, planned downlink volume,
  planned contacts, and satisfied/unsatisfied status; branch-comparison rows
  flatten the ratio and satisfied/unsatisfied counts for operator scan and
  Pareto comparison, and strategy recommendations explain the same
  collection-latency objective satisfaction for the recommended branch.
  Operator-review and Cadence-import strategy rows preserve that explanation in
  their `source_recommendation` context. A low mission-state `storage_margin`
  can derive the same event as a downlink-relief branch, requiring one
  additional contact
  beyond the current planned count and preserving `storage_margin_low` in the
  event and staged candidate feasibility metadata. Downlink addition repair
  metadata keeps the triggering reason specific to downlink completion,
  collection latency, storage relief, or downlink-margin pressure. When the
  branch source refresh carries a
  semantic candidate-diff replacement row, V3 preserves that row in staged
  downlink repair and feasibility metadata before adding the candidate to the
  branch plan, then lifts it into approval-review rows for import gates.
- `fuel_preservation_mode`: changes strategic fuel-preservation scoring.

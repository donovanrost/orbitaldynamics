# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
LinkCapacity triage-summary extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract link-capacity report row normalization, row-derived count/throughput
aggregation, station/contact/reservation routing, assumptions, and compact
summary construction into
`OrbitalDynamics.Communications.LinkCapacity.Summary`.
Preserve all LinkCapacity and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `communications/link_capacity.ex` at 1,904 lines, the
  largest ordinary eligible facade.
- LinkCapacity already delegates nine focused responsibilities, while the
  compact triage-summary builder remains inline at lines 768-933 with its
  row-derived aggregation/routing helper family in the facade.
- The selected block has one responsibility: project an existing
  `link_capacity_report.v1` into its compact artifact-only summary.
- Link-capacity report construction, contact validation, throughput/downlink
  evidence resolution, approval policy, relay data paths, and all public
  contracts remain outside the boundary.
- Exact row normalization, fallback precedence, count/sum semantics, stable-ID
  sorting, station/contact/reservation routing, assumptions, omission behavior,
  public facade output, and error behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
StationCalendar reservation-review summary extraction, selected in `0da707f7`
and implemented in `0635b27d`.
`station_calendar.ex` moved from 1,911 to 1,814 lines; the dedicated
ReservationReviewSummary owner is 129 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `communications/link_capacity.ex` is now the largest ordinary
eligible facade at 1,904 lines, followed by ContactFilter and
RecommendationRiskContext.

Blocked:
No.

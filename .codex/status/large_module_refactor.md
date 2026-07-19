# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactContention station-calendar context extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract station availability precedence, capacity fraction/percent contracts,
capability metadata, capacity aggregation, reservation/provider context
aggregation, and the station-calendar context field contract into
`OrbitalDynamics.Communications.ContactContention.StationCalendarContext`.
Preserve all ContactContention and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `communications/contact_contention.ex` at 1,978 lines,
  the largest ordinary eligible facade.
- ContactContention already delegates to seven focused owners, while the
  station-calendar context builder and helper family still occupy lines
  1,012-1,275 and its availability/capacity contracts remain at lines 19-66.
- The selected block has one responsibility: aggregate normalized station
  availability, capacity, provider, reservation, direction, trust-boundary,
  and expiration evidence for contention groups and recommendations.
- Group detection, timing, feedback, contact identity/normalization, capacity
  demand, priority policy, resolution summaries, approval policy, and all
  other capability contracts remain outside the boundary.
- Exact path ordering, unit metadata, availability severity/aliases, fraction
  min/max behavior, list normalization, field names, group/recommendation
  reports, summaries, and error behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending strict focused baseline, exact old/new public parity, focused and
adjacent tests, static ownership checks, xref, strict warning-clean compile,
formatting, and diff checks.

Behavior/schema changes:
None intended.

Last completed slice:
ResourceProjection station-capacity evidence extraction, selected in
`438a67a8` and implemented in `4ca5f9fb`.
`resource_projection.ex` moved from 1,981 to 1,789 lines; the dedicated
StationCapacityEvidence owner is 255 lines.

Next candidate:
Complete the selected ContactContention station-calendar context extraction.

Blocked:
No.

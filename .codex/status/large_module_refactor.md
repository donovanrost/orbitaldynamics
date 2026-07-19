# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactFilter provider-counteroffer context extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract the provider-counteroffer field contract, depth-limited nested/overlap
evidence lookup, candidate-before-station precedence, presence detection,
context insertion, and explicit/derived timing deltas into
`OrbitalDynamics.Communications.ContactFilter.ProviderCounterofferContext`.
Preserve all ContactFilter and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `communications/contact_filter.ex` at 2,062 lines,
  the largest ordinary eligible facade.
- ContactFilter currently has one extracted contact-normalization owner; its
  provider-counteroffer contract remains at lines 38-50 and its cohesive
  context/value/delta helper family remains at lines 1,287-1,437.
- The same source-value lookup also drives counteroffer review detection near
  line 810, so the new owner will expose that operation rather than duplicating
  traversal logic.
- Candidate normalization, suppression decisions, station matching and
  reservation evidence, provider contention, approval policy, report
  aggregation, feedback validation, and capacity handling remain outside the
  boundary.
- Exact field order, candidate-before-station precedence, nested source-entry
  and overlap search order, depth limit, unknown-negotiation omission, sparse
  insertion, explicit-delta precedence, numeric coercion, and derived timing
  delta behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending strict focused baseline, exact old/new public parity, focused and
adjacent tests, static ownership checks, xref, strict warning-clean compile,
formatting, and diff checks.

Behavior/schema changes:
None intended.

Last completed slice:
StationCalendar precedence-summary extraction, selected in `2bfb28f3` and
implemented in `b0d0e175`.
`communications/station_calendar.ex` moved from 2,068 to 1,911 lines; the
dedicated precedence-summary owner is 218 lines.

Next candidate:
Complete the selected ContactFilter provider-counteroffer context extraction.

Blocked:
No.

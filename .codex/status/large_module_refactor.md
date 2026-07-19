# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactIntent capacity-evidence extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract station/required capacity path contracts, capability and artifact
assumption metadata, station-capacity evidence aggregation, required-capacity
selection/source classification, nested source-calendar lookup, and unit
normalization into
`OrbitalDynamics.Communications.ContactIntent.CapacityEvidence`. Preserve all
ContactIntent and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `communications/contact_intent.ex` at 2,038 lines,
  the largest ordinary eligible facade.
- ContactIntent's station/required capacity path contracts occupy lines 77-184;
  the corresponding context/source/value helper family remains in the facade
  at lines 1,231-1,357.
- The same owner can supply the capability metadata and summary assumptions
  derived from those contracts, avoiding duplicated path declarations.
- Activity/timeline normalization, contact identity, station availability and
  reservations, policy classification, summary routing, feedback evidence,
  provider results, and cadence handoff remain outside the boundary.
- Exact path ordering, fraction/percent unit metadata, direct-before-nested
  required-capacity precedence, source classification, source-calendar
  traversal, numeric-string parsing, percent conversion, unit-interval
  validation, station min/max aggregation, and sparse output must remain
  unchanged.

Implementation:
Pending.

Verification:
Pending strict focused baseline, exact old/new public parity, focused and
adjacent tests, static ownership checks, xref, strict warning-clean compile,
formatting, and diff checks.

Behavior/schema changes:
None intended.

Last completed slice:
ResourceFilter summary extraction, selected in `c2ec6ed6` and implemented in
`4af22e46`.
`resource_filter.ex` moved from 2,059 to 1,964 lines; the dedicated summary
owner is 161 lines.

Next candidate:
Complete the selected ContactIntent capacity-evidence extraction.

Blocked:
No.

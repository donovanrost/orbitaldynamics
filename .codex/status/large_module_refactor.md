# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Ground-network communications JSON-property family extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract the ten contiguous command-window, station calendar/reservation,
link-capacity, relay-data-path, and contact-allocation clauses from
`JsonSchemaPropertyRouter` into a ground-network communications family owner.
Keep the parent router's exact guarded and literal clause heads/order as
delegations.

Selection evidence:
- The parent router remains 1,021 lines across 76 contract-family clauses.
- Ten adjacent clauses form a roughly 210-line ground-network communications
  boundary covering twenty related contracts.
- The bodies already delegate through focused ground-network, link, relay, and
  allocation dispatchers with shared lazy providers/context/fallback.
- No recursive parent callback or cross-family property lookup is required;
  the only shared alias is the existing timeline-context schema owner.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Strategy/planning-analysis JSON-property family extraction, selected in
`15add911` and implemented in `fd11d950`. The parent router moved from 1,071 to
1,021 lines.

Next candidate:
Implement and verify the selected ground-network communications split, then
re-rank the adjacent filter/resource/contention cohort.

Blocked:
No.

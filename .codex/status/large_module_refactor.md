# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operational readiness/handoff JSON-property family extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract the six contiguous readiness-gate, quality-gate, specialized-quality,
operational-readiness, operator-review, and Cadence-import clauses from
`JsonSchemaPropertyRouter` into an operational readiness/handoff family owner.
Keep the parent router's exact guarded and literal clause heads/order as
delegations.

Selection evidence:
- The parent router remains 814 lines across 76 contract-family clauses.
- Six adjacent clauses form a roughly 105-line operational readiness/handoff
  boundary covering twelve related contracts.
- The bodies already delegate through readiness, quality, and handoff
  dispatchers with shared lazy providers/context/fallback.
- No recursive parent callback or cross-family property lookup is required;
  the existing readiness validation alias moves with the family.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Objective/optimizer JSON-property family move, selected in `4b8ee80c` and
implemented in `d75f423d`. The parent router moved from 864 to 814 lines.

Next candidate:
Implement and verify the selected operational readiness/handoff split, then
re-rank the remaining maneuver/strategy/activity tail.

Blocked:
No.

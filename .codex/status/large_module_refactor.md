# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline report/state JSON-property family extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract the six contiguous timeline feedback, integrity, dependency-impact,
publication, activity-state, and activity-precondition clauses from
`JsonSchemaPropertyRouter` into a timeline report/state family owner. Keep the
parent router's exact clause heads/order as delegations and reuse shared
property support without adding a recursive callback.

Selection evidence:
- The parent router remains 1,226 lines across 76 contract-family clauses.
- Six adjacent clauses form a 114-line timeline report/state boundary across
  focused timeline dispatchers.
- The cohort shares only lazy providers, stable-ID context, fallback, and the
  existing timeline-context schema owner.
- No clause recursively re-enters the parent property router, so the split is a
  direct mechanical family move.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Campaign artifact JSON-property family extraction, selected in `a8372d62` and
implemented in `52d33f59`. The parent router moved from 1,241 to 1,226 lines.

Next candidate:
Implement and verify the selected timeline family split, then re-rank the
adjacent result-artifact/contact-planning families.

Blocked:
No.

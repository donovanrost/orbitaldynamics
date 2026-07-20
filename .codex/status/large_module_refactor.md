# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Contact-planning JSON-property extraction.

Status:
Selected; implementation pending.

Selected boundary:
Move the contact-intent, contact-intent-summary, and proposed-contact property
bodies from `JsonSchemaPropertyRouter` into a new
`ContactPlanningPropertyRouter`. Keep the parent router's exact literal clause
heads/order as delegations.

Selection evidence:
- Only eleven property bodies remain inline in the 641-line parent router.
- These three bodies all dispatch through `ContactPlanningPropertyDispatch`
  and form a roughly 45-line contact-intent/proposal boundary.
- A dedicated owner needs only the shared provider/context/fallback support.
- No recursive parent callback, embedded-schema callback, or cross-family
  property lookup is required.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Strategy/planning artifact JSON-property family expansion, selected in
`bbe8cc87` and implemented in `51a9b3db`. The parent router moved from 696 to
641 lines.

Next candidate:
Implement and verify the selected contact-planning extraction, then re-rank
the remaining inline router routes against the public `Schema` facade's
provider-helper boundaries.

Blocked:
No.

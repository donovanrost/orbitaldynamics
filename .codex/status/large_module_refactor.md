# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Contact-planning JSON-property extraction.

Status:
Completed and pushed.

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
Selected in `eebf7804` and implemented in `fd610981`.
`JsonSchemaPropertyRouter` retains all 76 public route heads in their original
order and delegates the three selected bodies to the new
`ContactPlanningPropertyRouter`. The owner contains only contact intent,
summary, and proposal dispatch and shared lazy provider/context/fallback
support.

Verification:
- Strict focused schema/validation baseline and post-change suites both passed:
  359 tests, 0 failures.
- AST-rendered comparison confirmed all three moved bodies are exact and all 76
  parent route heads remain exact and ordered.
- Xref reports three runtime edges from the parent to the contact-planning
  owner.
- Schema export regenerated 121 schemas plus the bundle with no checked-in
  artifact diff.
- Strict full compile passed for 4,106 files with warnings as errors.
- Formatting, diff checks, and bounded two-file review passed.
- The parent router shrank from 641 to 615 lines; the new owner is 45 lines.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Contact-planning JSON-property extraction, selected in `eebf7804` and
implemented in `fd610981`. The parent router moved from 641 to 615 lines.

Next candidate:
Re-rank the remaining inline router routes against the public `Schema`
facade's provider-helper boundaries.

Blocked:
No.

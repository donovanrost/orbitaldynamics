# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Contact-allocation provider-reservation-request-summary callback-bag collapse.

Status:
Selected; implementation not started.

Selected slice:
Replace the 22-entry provider-reservation-request-summary keyword bag with
direct primitive, capability, and contact-allocation report owners, retaining
only the explicit row validator that still requires Schema-owned report
context.

Why this slice:
Live inventory leaves `schema.ex` at 10,602 lines. The 670-line
provider-reservation-request owner routes 22 dependencies through lookup/apply;
21 already have direct owners, while only contact-allocation row validation
crosses a genuine Schema-owned boundary.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, all
provider-reservation-request-summary fields, exact paths/messages/order,
consumers, deterministic artifacts, and schema exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/contact_allocation_provider_reservation_request_summary_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused provider-reservation/contact-allocation and candidate-refresh tests
- broader campaign-planner/operator-review/schema regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No provider-reservation-request-summary keyword bag or lookup/apply trampolines
remain; its shared dependencies are direct, only the row validator is explicit,
implicit equality messages remain exact, focused/broader/export checks pass,
and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Not yet verified.

Last completed slice:
Contact-allocation station-pressure-summary callback collapse published as
`12cbf1a6`: `schema.ex` fell from 10,637 to 10,602 lines and the owner from 565
to 454; the 25-entry factory became one explicit row-validator hook. Two hundred
eighty-four focused, 1,340 attributable broader, and 24 export tests passed;
compile, regeneration, xref, format, diff hygiene, and bounded review were clean.

Blocked:
No.

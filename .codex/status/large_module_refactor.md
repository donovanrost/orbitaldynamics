# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Contact-allocation provider-reservation-request-summary callback-bag collapse.

Status:
Implemented, verified, reviewed, and ready to publish.

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
The 22-entry provider-reservation-request-summary callback bag and all
lookup/apply trampolines are gone. The extracted owner now calls primitive,
stable-ID, capability, and contact-allocation report owners directly; Schema
passes only `&validate_contact_allocation_row/3`. One newly orphaned Schema
reservation-ID facade also disappeared. `schema.ex` fell from 10,602 to 10,567
lines and the owner from 670 to 552, for 153 net deleted lines across the slice.

Verification gaps:
- Full repository suite not run. The standard broader lane remains at the
  baseline 1,340/1,345 with the same five known campaign-planner failures
  attributable at `6f1f0ac1`.
- Focused provider-reservation/contact-allocation coverage passed 275 tests;
  export coverage passed 24. Compile with warnings as errors, checked-in schema
  regeneration, compile-connected xref (three allowed edges), format, diff
  hygiene, and independent bounded review were clean.

Last completed slice:
Contact-allocation provider-reservation-request-summary callback collapse;
publication commit pending. The 22-entry factory became one explicit
row-validator hook, with 275 focused, 1,340 attributable broader, and 24 export
tests passing; compile, regeneration, xref, format, diff hygiene, and bounded
review were clean.

Blocked:
No.

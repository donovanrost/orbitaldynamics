# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Contact-allocation aggregate-summary callback-bag collapse.

Status:
Selected; implementation not started.

Selected slice:
Replace the 33-entry aggregate-summary domain keyword bag with direct capability
and contact-allocation report owners, retaining only the explicit row and
capacity-pack-group validators that still require Schema-owned report context.

Why this slice:
Live inventory leaves `schema.ex` at 10,441 lines. The 1,330-line aggregate
summary owner routes 33 domain dependencies through lookup/apply; 31 already
have direct capability or report owners, while only contact-allocation row and
capacity-pack-group validation cross genuine Schema-owned boundaries.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, all contact-allocation-summary
fields, exact paths/messages/order, consumers, deterministic artifacts, and
schema exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/contact_allocation_summary_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused aggregate-summary/contact-allocation and candidate-refresh tests
- broader campaign-planner/operator-review/schema regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No aggregate-summary domain keyword bag or lookup/apply trampolines remain; its
shared dependencies are direct, only the row and capacity-pack-group validators
are explicit, numeric/equality messages remain exact, focused/broader/export
checks pass, and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Not yet verified.

Last completed slice:
Contact-allocation reservation-conflict-summary callback collapse published as
`5a9baf23`: `schema.ex` fell from 10,515 to 10,441 lines and the owner from 792
to 616; the 33-entry factory became one explicit row-validator hook and eight
facade/import orphans disappeared. Two hundred seventy-seven focused, 1,340
attributable broader, and 24 export tests passed; compile, regeneration, xref,
format, diff hygiene, and bounded review were clean.

Blocked:
No.

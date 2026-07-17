# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Contact-allocation capacity-pack-summary callback-bag collapse.

Status:
Selected; implementation not started.

Selected slice:
Replace the 30-entry capacity-pack-summary keyword bag with direct primitive,
capability, and contact-allocation report owners, retaining only the explicit
row and capacity-pack-group validators that still require Schema-owned report
context.

Why this slice:
Live inventory leaves `schema.ex` at 10,567 lines. The 874-line capacity-pack
owner routes 30 dependencies through lookup/apply; 28 already have direct
owners, while contact-allocation row and capacity-pack-group validation cross
genuine Schema-owned boundaries.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, all capacity-pack-summary fields,
exact paths/messages/order, consumers, deterministic artifacts, and schema
exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/contact_allocation_capacity_pack_summary_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused capacity-pack/contact-allocation and candidate-refresh tests
- broader campaign-planner/operator-review/schema regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No capacity-pack-summary keyword bag or lookup/apply trampolines remain; its
shared dependencies are direct, only the row and capacity-pack-group validators
are explicit, numeric/equality messages remain exact, focused/broader/export
checks pass, and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Not yet verified.

Last completed slice:
Contact-allocation provider-reservation-request-summary callback collapse
published as `21b11ea2`: `schema.ex` fell from 10,602 to 10,567 lines and the
owner from 670 to 552; the 22-entry factory became one explicit row-validator
hook and one facade orphan disappeared. Two hundred seventy-five focused, 1,340
attributable broader, and 24 export tests passed; compile, regeneration, xref,
format, diff hygiene, and bounded review were clean.

Blocked:
No.

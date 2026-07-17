# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Contact-allocation reservation-conflict-summary callback-bag collapse.

Status:
Selected; implementation not started.

Selected slice:
Replace the 33-entry reservation-conflict-summary keyword bag with direct
primitive, capability, and contact-allocation report owners, retaining only the
explicit row validator that still requires Schema-owned report context.

Why this slice:
Live inventory leaves `schema.ex` at 10,515 lines. The 792-line
reservation-conflict owner routes 33 dependencies through lookup/apply; 32
already have direct owners, while only contact-allocation row validation crosses
a genuine Schema-owned boundary.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, all reservation-conflict-summary
fields, exact paths/messages/order, consumers, deterministic artifacts, and
schema exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/contact_allocation_reservation_conflict_summary_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused reservation-conflict/contact-allocation and candidate-refresh tests
- broader campaign-planner/operator-review/schema regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No reservation-conflict-summary keyword bag or lookup/apply trampolines remain;
its shared dependencies are direct, only the row validator is explicit,
numeric/equality messages remain exact, focused/broader/export checks pass, and
bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Not yet verified.

Last completed slice:
Contact-allocation capacity-pack-summary callback collapse published as
`a78dfd9b`: `schema.ex` fell from 10,567 to 10,515 lines and the owner from 874
to 690; the 30-entry factory became two explicit validator hooks and two facade
orphans disappeared. Two hundred seventy-seven focused, 1,340 attributable
broader, and 24 export tests passed; compile, regeneration, xref, format, diff
hygiene, and bounded review were clean.

Blocked:
No.

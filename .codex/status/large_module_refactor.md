# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Contact-allocation station-pressure-summary callback-bag collapse.

Status:
Selected; implementation not started.

Selected slice:
Replace the 25-entry station-pressure-summary keyword bag with direct primitive,
capability, and contact-allocation report owners, retaining only the explicit
row validator that still requires Schema-owned report context.

Why this slice:
Live inventory leaves `schema.ex` at 10,637 lines. The 565-line station-pressure
owner routes 25 dependencies through lookup/apply; 24 already have direct
owners, while only contact-allocation row validation crosses a genuine
Schema-owned boundary.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, all station-pressure-summary fields,
exact paths/messages/order, consumers, deterministic artifacts, and schema
exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/contact_allocation_station_pressure_summary_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused station-pressure/contact-allocation and candidate-refresh tests
- broader campaign-planner/operator-review/schema regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No station-pressure-summary keyword bag or lookup/apply trampolines remain; its
shared dependencies are direct, only the row validator is explicit, implicit
equality messages remain exact, focused/broader/export checks pass, and bounded
review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Not yet verified.

Last completed slice:
Timeline-publication-summary callback collapse published as `1a668690`:
`schema.ex` fell from 10,686 to 10,637 lines and the owner from 703 to 599; the
19-entry factory, lookup/apply trampolines, handoff callback threading, and one
facade orphan disappeared. Four hundred ninety-four focused, 1,340 attributable
broader, and 24 export tests passed; compile, regeneration, xref, format, diff
hygiene, and bounded review were clean.

Blocked:
No.

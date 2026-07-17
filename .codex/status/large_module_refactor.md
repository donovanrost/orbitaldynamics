# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Contact-allocation-handoff domain callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Replace the two-entry `ContactAllocationHandoffContracts` bag with direct
priority-override ownership and one explicit duplicate-evidence validator.

Why this slice:
Live inventory leaves `schema.ex` at 11,309 lines. Only one function in the
936-line handoff owner and its sole caller use this bag. Priority-override
validation already has a concrete shared owner; only duplicate-evidence
validation crosses the remaining report-domain boundary.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, contact-allocation handoff fields,
duplicate and override count evidence, exact paths/messages/order, consumers,
deterministic artifacts, and schema exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/contact_allocation_handoff_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused contact-allocation handoff and operator-review tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No contact-allocation-handoff callback bag or lookup/apply trampolines remain;
priority-override ownership is direct and only the duplicate-evidence validator
stays explicit; focused, broader, and export checks pass; and bounded review
finds no blocker.

Outcome:
Pending.

Verification gaps:
- Full repository suite not run.
- The broader batch has five existing campaign-planner failures. The same five
  fail in the same four files on pre-slice commit `6f1f0ac1`; the attributable
  result is 1,340/1,340.

Last completed slice:
Candidate-refresh-report domain callback-bag collapse published as `a6453475`:
`schema.ex` fell from 11,332 to 11,309 lines and its owner from 332 to 275. All
four dependencies became direct and inert callback arguments disappeared.
One hundred eighty-eight focused, 1,340 attributable broader, and 24 export
tests passed; compile, regeneration, xref, format, diff hygiene, and bounded
review were clean.

Blocked:
No.

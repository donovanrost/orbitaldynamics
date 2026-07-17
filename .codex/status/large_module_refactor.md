# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Contact-intent-summary callback-bag collapse.

Status:
Selected; implementation not started.

Selected slice:
Replace the 21-entry `ContactIntentSummaryContracts` keyword bag with direct
shared owners and relocate its contact-intent capability-derived assumption
helpers out of `schema.ex`.

Why this slice:
Live inventory leaves `schema.ex` at 10,818 lines. The adjacent 756-line summary
owner still routes 21 primitive, stable-ID, numeric-map, direction-routing, and
capability dependencies through lookup/apply. Every validator already has an
extracted owner, while four capability transformation helpers remain in the
facade only to serve this summary and its JSON schema.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, all contact-intent-summary fields,
exact paths/messages/order, consumers, deterministic artifacts, and schema
exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/contact_intent_summary_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused contact-intent-summary and candidate-refresh tests
- broader campaign-planner/operator-review/schema regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No contact-intent-summary keyword bag or lookup/apply trampolines remain; its
validators and capabilities are direct, JSON-schema assumptions reuse the
relocated owner, focused/broader/export checks pass, and bounded review finds no
blocker.

Outcome:
Pending.

Verification gaps:
- Not yet verified.

Last completed slice:
Contact-intent callback and policy-field ownership collapse published as
`13d59360`: `schema.ex` fell from 11,079 to 10,818 lines; the 21-entry factory,
lookup/apply trampolines, and facade-owned policy lists disappeared. Nine
hundred eighty-four focused, 1,340 attributable broader, and 24 export tests
passed; compile, regeneration, xref, format, diff hygiene, and bounded review
were clean.

Blocked:
No.

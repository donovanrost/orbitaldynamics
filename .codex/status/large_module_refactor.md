# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Link-capacity-summary callback-bag collapse.

Status:
Selected; implementation not started.

Selected slice:
Replace the 16-entry `LinkCapacitySummaryContracts` keyword bag with direct
shared owners, direct its domain assumption validator to the extracted report
owner, and relocate link-capacity model-limit ownership out of `schema.ex`.

Why this slice:
Live inventory leaves `schema.ex` at 10,749 lines. The 501-line link-capacity
summary owner routes 16 primitive, collection, stable-ID, assumption, and
capability dependencies through lookup/apply. Every validator already has an
extracted owner; the facade wrappers add no context, and model limits can be
shared directly by validation and JSON schema generation.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, all link-capacity-summary fields,
exact paths/messages/order, consumers, deterministic artifacts, and schema
exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/link_capacity_summary_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused link-capacity summary/report and candidate-refresh tests
- broader campaign-planner/operator-review/schema regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No link-capacity-summary keyword bag or lookup/apply trampolines remain; its
validators, assumptions, and capabilities are direct, JSON schema reuses the
relocated model-limit owner, focused/broader/export checks pass, and bounded
review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Not yet verified.

Last completed slice:
Contact-intent-summary callback collapse published as `847778fa`: `schema.ex`
fell from 10,818 to 10,749 lines and the owner from 756 to 653; the 21-entry
factory, lookup/apply trampolines, duplicated capability transforms, and five
facade orphans disappeared. Three hundred sixty-two focused, 1,340 attributable
broader, and 24 export tests passed; compile, regeneration, xref, format, diff
hygiene, and bounded review were clean.

Blocked:
No.

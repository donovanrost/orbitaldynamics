# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Contact-intent-summary callback-bag collapse.

Status:
Complete and ready to publish.

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
The 21-entry bag and every summary lookup/apply trampoline are gone. Primitive,
stable-ID, numeric-map, and direction-routing validators are direct. Contact
intent model limits and three capability-derived assumption transformations
now live with the summary owner, and JSON schema generation reuses them. The
factory, routing trampoline, duplicated assumption helpers, nested numeric-map
trampoline, and unused facade import disappeared. `schema.ex` fell from 10,818
to 10,749 lines and the summary owner from 756 to 653, for a net 172-line
reduction. Three hundred sixty-two focused, 1,340 attributable broader, and 24
export tests pass; compile, checked-in regeneration, compile-connected xref
within its existing three-edge threshold, format, and diff hygiene are clean.
Bounded review found no blocker and confirmed the full pipeline, defaults,
paths/messages, direct validators, routing delegation, capability transforms,
JSON-schema reuse, caller arity, and orphan cleanup.

Verification gaps:
- Full repository suite not run.
- The 1,345-test broader batch has the same five known campaign-planner baseline
  failures previously reproduced on pre-slice commit `6f1f0ac1`; the
  attributable result is 1,340/1,340.

Last completed slice:
Contact-intent callback and policy-field ownership collapse published as
`13d59360`: `schema.ex` fell from 11,079 to 10,818 lines; the 21-entry factory,
lookup/apply trampolines, and facade-owned policy lists disappeared. Nine
hundred eighty-four focused, 1,340 attributable broader, and 24 export tests
passed; compile, regeneration, xref, format, diff hygiene, and bounded review
were clean.

Blocked:
No.

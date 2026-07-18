# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema operational handoff property-dispatch extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move JSON-property dispatch/context assembly for operational-readiness report,
operator-review package, and Cadence import manifest into an internal
`Schema.OperationalHandoffPropertyDispatch` owner.

Why this slice:
`Schema` is 7,773 lines. These three adjacent operational handoff contracts
still build eager capability, readiness, review/import row, model-limit, and
scalar-count contexts in the facade, between already-delegated operational
summary families and unrelated maneuver/planning contracts.

Current coupling/problem:
The facade owns focused routing plus eager operational/review/import context
construction, including the operator-review scalar-count predicate lookup.

Public facade to preserve:
All `Schema` APIs; the three JSON Schema documents; checked-in exports,
deterministic ordering, focused fallback behavior, eager evaluation and scalar
field lookup order, and all errors.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/operational_handoff_property_dispatch.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The three clauses pass compact dependencies to the new owner; named contexts
and focused fallback routing move out of `Schema`; focused readiness,
operator-review, Cadence-import, and export tests pass; strict compile, full
byte-clean schema regeneration, and independent review are clean.

Verification gaps:
- Focused baseline, strict compile, export proof, and independent review remain.

Tests run:
- None yet for this selected slice.

Behavior/schema changes:
None intended.

Last completed slice:
Standalone communications schema dispatch published as implementation
`3f05cbe7` and handoff `b96fd80b`: focused 37/37, strict 3,658-file compile,
full byte-clean schema regeneration, and independent review passed.

Next candidate:
After this slice, remap the remaining direct property clauses in `Schema`.

Blocked:
No.

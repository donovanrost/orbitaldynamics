# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema planning-reference property-dispatch extraction.

Status:
Implementation published as `b4b57709`; handoff publication pending.

Selected slice:
Move focused JSON-property routing/context assembly for activity template,
capability catalog, accepted planning state, and manifest-field reference into
an internal `Schema.PlanningReferencePropertyDispatch` owner.

Why this slice:
`Schema` is 7,744 lines. These four adjacent planning-reference artifacts still
route directly through the facade; two build small contexts and two use direct
focused property functions.

Current coupling/problem:
The facade owns contract/pattern and state/delta contexts plus direct focused
predicate/property pairing for catalog and manifest references.

Public facade to preserve:
All `Schema` APIs; the four JSON Schema documents; checked-in exports,
deterministic ordering, focused fallback behavior, provider order and arity,
direct property routing, and all errors.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/planning_reference_property_dispatch.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The four clauses pass compact dependencies to the new owner; named contexts and
focused fallback routing move out of `Schema`; focused accepted-state/
registry/refresh/export tests pass; strict compile, full byte-clean schema
regeneration, and independent review are clean.

Verification gaps:
- None for this slice. Full checked-in schema regeneration is byte-identical.
- Independent review was clean. No API, schema, export, ordering,
  error-behavior, ownership, or behavioral finding remains.

Tests run:
- Baseline and post-change focused accepted-state/registry/refresh/export
  subset: 36 passed with warnings as errors.
- Strict forced compile: 3,667 files clean with warnings as errors.
- Full schema export regenerated every checked-in schema and bundle with zero
  diff.
- Public `Schema` definitions match selection commit `52ec3b58`; xref reports
  the dispatcher has only the `Schema` runtime caller.
- Format, changed/new-file whitespace, and `git diff --check` passed.
- Independent review confirmed exact direct property pairs, constants, accepted
  state provider order/arities, and untouched adjacent routes, then reran all
  proof clean.

Behavior/schema changes:
None intended.

Outcome:
Activity template, capability catalog, accepted planning state, and
manifest-field reference routes now delegate to
`PlanningReferencePropertyDispatch`. Implementation published as `b4b57709`.

Last completed slice:
Maneuver artifact schema dispatch published as implementation `ca7da9e7` and
handoff `048e1251`: focused 26/26, strict 3,666-file compile, full byte-clean
schema regeneration, and independent review passed.

Next candidate:
After this slice, remap the remaining direct property clauses in `Schema`.

Blocked:
No.

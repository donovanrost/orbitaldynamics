# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema migration property-dispatch extension.

Status:
Implementation published as `49c99fb8`; handoff publication pending.

Selected slice:
Move focused JSON-property routing/context assembly for schema-migration report
into the existing internal `Schema.SchemaValidationPropertyDispatch` owner.

Why this slice:
`Schema` is 7,733 lines. Only schema migration and candidate rejection remain
as direct focused clauses; schema migration belongs with the existing
schema-validation report/batch owner.

Current coupling/problem:
The facade owns migration contract/version, capability-derived status providers,
row schema, model limits, and focused fallback routing.

Public facade to preserve:
All `Schema` APIs; the schema-migration JSON Schema document; checked-in
exports, deterministic ordering, focused fallback behavior, provider order and
arity, capability lookup timing, and all errors.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/schema_validation_property_dispatch.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The clause passes compact dependencies to the existing owner; named context and
focused fallback routing move out of `Schema`; focused validation/registry/
export tests pass; strict compile, full byte-clean schema regeneration, and
independent review are clean.

Verification gaps:
- None for this slice. Full checked-in schema regeneration is byte-identical.
- Independent review was clean. No API, schema, export, ordering,
  error-behavior, ownership, or behavioral finding remains.

Tests run:
- Baseline and post-change focused validation/registry/export subset: 24 passed
  with warnings as errors.
- Strict forced compile: 3,667 files clean with warnings as errors.
- Full schema export regenerated every checked-in schema and bundle with zero
  diff.
- Public `Schema` definitions match selection commit `b40c4be7`; xref reports
  the dispatcher has only the `Schema` runtime caller.
- Format, changed-file whitespace, and `git diff --check` passed.
- Independent review confirmed exact six-key context and capability lookup
  timing, unchanged existing validation and adjacent routes, then reran all
  proof clean.

Behavior/schema changes:
None intended.

Outcome:
Schema-migration report routing now delegates to the existing
`SchemaValidationPropertyDispatch`. Implementation published as `49c99fb8`.

Last completed slice:
Planning-analysis model schema dispatch published as implementation `fba3dc77`
and handoff `6e089ea6`: focused 22/22, strict 3,667-file compile, full
byte-clean schema regeneration, and independent review passed.

Next candidate:
Extend the existing timeline-report owner for the final candidate-rejection
direct clause, then remove the unused facade focused helper.

Blocked:
No.

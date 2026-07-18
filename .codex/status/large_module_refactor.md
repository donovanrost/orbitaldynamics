# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema result artifact property-dispatch extraction.

Status:
Implementation published as `6b7ed38d`; handoff publication pending.

Selected slice:
Move JSON-property dispatch/context assembly for execution report, result
artifact, and resource summary into an internal
`Schema.ResultArtifactPropertyDispatch` owner.

Why this slice:
`Schema` is 7,752 lines. These three adjacent result-set artifacts share schema,
version, stable-ID, execution-contract, embedded-contract, and model-limit
context but still route directly through the facade.

Current coupling/problem:
The facade owns nine result artifact constants/providers plus focused fallback
routing across this cohesive result-set family.

Public facade to preserve:
All `Schema` APIs; the three JSON Schema documents; checked-in exports,
deterministic ordering, focused fallback behavior, provider order and arity,
and all errors.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/result_artifact_property_dispatch.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The three clauses pass compact dependencies to the new owner; named contexts
and focused fallback routing move out of `Schema`; focused result/resource/
execution/export tests pass; strict compile, full byte-clean schema
regeneration, and independent review are clean.

Verification gaps:
- None for this slice. Full checked-in schema regeneration is byte-identical.
- Independent review was clean. No API, schema, export, ordering,
  error-behavior, ownership, or behavioral finding remains.

Tests run:
- Baseline and post-change focused result/resource/execution/export subset:
  27 passed with warnings as errors.
- Strict forced compile: 3,665 files clean with warnings as errors.
- Full schema export regenerated every checked-in schema and bundle with zero
  diff.
- Public `Schema` definitions match selection commit `4dac9b40`; xref reports
  the dispatcher has only the `Schema` runtime caller.
- Format, changed/new-file whitespace, and `git diff --check` passed.
- Independent review confirmed exact constants, provider order/arities, and
  unchanged adjacent routes, then reran all proof clean.

Behavior/schema changes:
None intended.

Outcome:
Execution report, result artifact, and resource-summary routes now delegate to
`ResultArtifactPropertyDispatch`. Implementation published as `6b7ed38d`.

Last completed slice:
Contact-planning schema dispatch published as implementation `f2c56254` and
handoff `4affa8d6`: focused 40/40, strict 3,664-file compile, full byte-clean
schema regeneration, and independent review passed.

Next candidate:
After this slice, remap the remaining direct property clauses in `Schema`.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema maneuver artifact property-dispatch extraction.

Status:
Implementation published as `ca7da9e7`; handoff publication pending.

Selected slice:
Move JSON-property dispatch/context assembly for realized-state snapshot,
maneuver recommendation, and maneuver-review report into an internal
`Schema.ManeuverArtifactPropertyDispatch` owner.

Why this slice:
`Schema` is 7,744 lines. These three maneuver/state-review artifacts
collectively carry 11 activity/state/vector/row/model dependencies but still
route directly through the facade.

Current coupling/problem:
The facade owns realized-state components and limits, maneuver recommendation
contract/vector/limits, and maneuver-review row/pattern/limits across separated
clauses.

Public facade to preserve:
All `Schema` APIs; the three JSON Schema documents; checked-in exports,
deterministic ordering, focused fallback behavior, provider order and arity,
and all errors.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/maneuver_artifact_property_dispatch.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The three clauses pass compact dependencies to the new owner; named contexts
and focused fallback routing move out of `Schema`; focused maneuver/state/
import/export tests pass; strict compile, full byte-clean schema regeneration,
and independent review are clean.

Verification gaps:
- None for this slice. Full checked-in schema regeneration is byte-identical.
- Independent review was clean. No API, schema, export, ordering,
  error-behavior, ownership, or behavioral finding remains.

Tests run:
- Baseline and post-change focused maneuver/state/import/export subset:
  26 passed with warnings as errors.
- Strict forced compile: 3,666 files clean with warnings as errors.
- Full schema export regenerated every checked-in schema and bundle with zero
  diff.
- Public `Schema` definitions match selection commit `91db634d`; xref reports
  the dispatcher has only the `Schema` runtime caller.
- Format, changed/new-file whitespace, and `git diff --check` passed.
- Independent review confirmed exact constants, lazy provider order/arities,
  and unchanged intervening routes, then reran all proof clean.

Behavior/schema changes:
None intended.

Outcome:
Realized-state snapshot, maneuver recommendation, and maneuver-review report
routes now delegate to `ManeuverArtifactPropertyDispatch`. Implementation
published as `ca7da9e7`.

Last completed slice:
Result artifact schema dispatch published as implementation `6b7ed38d` and
handoff `bc56d049`: focused 27/27, strict 3,665-file compile, full byte-clean
schema regeneration, and independent review passed.

Next candidate:
After this slice, remap the remaining direct property clauses in `Schema`.

Blocked:
No.

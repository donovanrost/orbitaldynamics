# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema policy capability-context extraction.

Status:
Completed and pushed.

Selected boundary:
Extract the capability-derived policy model-limit projection into
`OrbitalDynamics.Schema.PolicyCapabilityContext`.
Import that focused internal API into the Schema facade.
Keep policy schema construction, property dispatch, approval/policy
validation, and all public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,184 lines.
- The private projection converts Policy capability atoms to strings and feeds
  two property-dispatch paths plus four validation paths.
- Importing the focused API preserves existing callback captures and
  validation calls while leaving every consumer in its current owner.
- Exact model-limit values and ordering, generated JSON Schema, validation
  results, and checked-in exports must remain unchanged.

Implementation:
Added `OrbitalDynamics.Schema.PolicyCapabilityContext`, which now owns the
capability-derived policy model-limit projection. `OrbitalDynamics.Schema`
imports that single focused API for its existing schema and validation
consumers.
`schema.ex` moved from 6,184 to 6,181 lines; the dedicated owner is 9 lines.

Verification:
- Strict focused policy/validation/contact-feedback/export baseline before
  extraction: 22 passed.
- The same strict focused suite after extraction: 22 passed.
- Strict full schema-export task plus adjacent contact-allocation,
  campaign-plan, and fixture-visibility coverage: 12 passed.
- `mix xref callers OrbitalDynamics.Schema.PolicyCapabilityContext` reports
  only `lib/orbital_dynamics/schema.ex (export)`.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,064 files.
- Implementation commit `acf2057b` pushed to `main`.

Behavior/schema changes:
None. Public facades, model-limit values and ordering, generated JSON Schema,
validation behavior, and checked-in exports remain unchanged.

Last completed slice:
Schema policy capability-context extraction, selected in `4573312c` and
implemented in `acf2057b`.
`schema.ex` moved from 6,184 to 6,181 lines; the dedicated
PolicyCapabilityContext owner is 9 lines.

Next candidate:
Re-rank the remaining Schema capability/model-limit responsibility clusters.

Blocked:
No.

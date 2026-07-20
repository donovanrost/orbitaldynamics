# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema validation-policy artifact context extraction.

Status:
Completed and pushed.

Selected boundary:
Add a `ValidationPolicyValidation` owner-default entry point for
`validation_tolerance_policy.v1` and `backend_acceptance_policy.v1`. Derive
requirements from `ValidationPolicyRegistryContracts`, route both direct
`Schema` clauses, and keep the `ValidationPolicyContracts` APIs unchanged.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,860 lines; the other
  targeted public facades are now 164 to 524 lines.
- The two adjacent clauses repeat required-field setup and delegate to the same
  `ValidationPolicyContracts` module.
- `ValidationPolicyRegistryContracts` owns every selected requirement.
- Neither selected route needs callbacks, recursive `Schema` lookup, model
  limits, or facade-local context.
- `capability_catalog.v1` remains out of scope because its validation needs the
  facade-wide `@contracts` map and therefore has a distinct context boundary.

Implementation:
Added `ValidationPolicyValidation` as the registry-backed family owner for the
two selected artifacts and routed their direct `Schema` validation clauses
through it. `schema.ex` moved from 4,860 to 4,851 lines.

Verification:
- Strict focused baseline: 17 tests passed.
- Focused plus adjacent validation and export coverage after extraction:
  39 tests passed.
- Full schema export completed with no checked-in artifact changes.
- Static routing review found exactly the two intended direct facade routes.
- `mix xref trace` confirmed both runtime calls originate in `schema.ex`; a
  bounded production search found no other owner callers.
- Formatting and `git diff --check` passed.
- Strict forced compile passed across 4,082 files with warnings as errors.
- Bounded diff review confirmed registry-owned requirements, contract routing,
  validation ordering, validation paths, and the capability-catalog exclusion
  remain unchanged.
- Implementation committed and pushed as `5b893e8e`.

Behavior/schema changes:
None. Required fields, validation ordering and paths, public `Schema` APIs,
validation results, and checked-in exports remain unchanged.

Last completed slice:
Schema validation-policy artifact context extraction, selected in `0b0162c1`
and implemented in `5b893e8e`.
`schema.ex` moved from 4,860 to 4,851 lines.

Next candidate:
Re-rank the remaining Schema responsibility clusters and select the next
facade-preserving extraction.

Blocked:
No.

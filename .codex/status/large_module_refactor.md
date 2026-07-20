# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema validation-policy artifact context extraction.

Status:
Selected; implementation pending.

Selected boundary:
Add a `ValidationPolicyArtifactValidation` owner-default entry point for
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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, validation ordering and paths, public `Schema`
APIs, validation results, and checked-in exports must remain unchanged.

Last completed slice:
Schema execution/reproducibility validation context extraction, selected in
`2564cb45` and implemented in `090c4b43`.
`schema.ex` moved from 4,864 to 4,860 lines.

Next candidate:
Implement and verify the selected validation-policy artifact context, then
re-rank the remaining Schema responsibility clusters.

Blocked:
No.

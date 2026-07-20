# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema model-capability validation context extraction.

Status:
Completed and pushed.

Selected boundary:
Add ModelCapabilityValidation owner-default entry points for environment model,
environment provider, and subsystem model capability artifacts. Derive
requirements from ModelCapabilityRegistryContracts, route all three direct
Schema clauses, and keep ModelCapabilityContracts APIs unchanged.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,896 lines; the other
  targeted public facades are now 164 to 524 lines.
- Three direct clauses repeat required-field setup and family routing.
- ModelCapabilityRegistryContracts owns every required-field definition.
- ModelCapabilityContracts owns all three artifact-specific validators.
- No route needs callbacks, recursive Schema lookup, or facade-local context.

Implementation:
Added ModelCapabilityValidation with one registry-backed family entry point and
three specialized contract routes. Routed all three direct Schema clauses to
the owner. `schema.ex` moved from 4,896 to 4,888 lines.

Verification:
- Strict validation/registry/resource baseline before extraction: 13 passed.
- The same focused coverage plus capability/environment tests after extraction:
  35 passed.
- The full schema-export task completed and produced no checked-in changes.
- Exact static inspection confirms three direct owner routes and no remaining
  facade-local model-capability validation logic.
- `mix xref callers OrbitalDynamics.Schema.ModelCapabilityValidation` reports
  only the expected Schema facade runtime caller.
- `mix format --check-formatted` and `git diff --check` passed.
- Strict forced compile passed across 4,079 files with no warnings.
- Bounded local review confirmed registry requirements, contract routing,
  validation ordering, and issue paths are preserved.
- Implementation commit `6f7789aa` pushed to `main`.

Behavior/schema changes:
None. Required fields, validation ordering and paths, public Schema APIs,
validation results, and checked-in exports remain unchanged.

Last completed slice:
Schema model-capability validation context extraction, selected in `c49cbd4f`
and implemented in `6f7789aa`.
`schema.ex` moved from 4,896 to 4,888 lines.

Next candidate:
Re-rank the remaining Schema responsibility clusters. Preserve the
context-bearing CommonJsonSchema wrappers unless a separate exact ownership
boundary is proven.

Blocked:
No.

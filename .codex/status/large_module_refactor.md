# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema model-capability validation context extraction.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, validation ordering and paths, public Schema
APIs, validation results, and checked-in exports must remain unchanged.

Last completed slice:
Schema operational-readiness artifact owner routing, selected in `ba0bd916` and
implemented in `5eb1a198`.
`schema.ex` moved from 4,889 to 4,896 lines while ten validation-context copies
moved to the existing owner.

Next candidate:
Implement and verify the selected model-capability context extraction, then
re-rank the remaining Schema responsibility clusters.

Blocked:
No.

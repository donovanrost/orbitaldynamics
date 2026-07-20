# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema realized-state validation context extraction.

Status:
Selected; implementation pending.

Selected boundary:
Add `RealizedStateValidation` owner-default entry points for
`realized_activity.v1` and `realized_state_snapshot.v1`. Derive requirements
from `RealizedStateRegistryContracts`, route both direct `Schema` clauses, and
keep both artifact-specific contract APIs unchanged.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,826 lines; the other
  targeted public facades are now 164 to 524 lines.
- The two adjacent clauses repeat required-field setup and form the exact family
  owned by `RealizedStateRegistryContracts`.
- `RealizedActivityContracts` and `RealizedStateSnapshotContracts` own all
  artifact-specific validation.
- Neither route needs callbacks, recursive `Schema` lookup, model limits, or
  facade-local context.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, validation ordering and paths, public `Schema`
APIs, validation results, and checked-in exports must remain unchanged.

Last completed slice:
Schema contact-intent validation context extraction, selected in `8d5283b2`
and implemented in `a60283db`.
`schema.ex` moved from 4,829 to 4,826 lines.

Next candidate:
Implement and verify the selected realized-state context, then re-rank the
remaining Schema responsibility clusters.

Blocked:
No.

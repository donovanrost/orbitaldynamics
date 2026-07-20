# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema artifact-validation router extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract the complete specialized `validate_contract/3` clause set and generic
required-field fallback from `Schema` into an `ArtifactValidationRouter`.
Route `ArtifactValidation` through the new module while preserving clause order,
owner calls, literal contract identities, issue paths, and fallback behavior.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 3,818 lines; the other
  targeted public facades are now 164 to 524 lines.
- Every specialized clause now delegates to a focused validation owner; the
  facade still owns roughly 590 lines of mechanical contract-name routing.
- The router depends only on those owners plus primitive required-field
  validation and no longer needs facade callbacks or private state.
- Replacing module attributes with their unchanged literal contract identities
  avoids duplicating the facade's JSON-schema metadata surface.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Clause order, owner calls, contract identities, required-field
fallback, issue paths and ordering, public `Schema`, validation results, and
checked-in exports must remain unchanged.

Last completed slice:
Schema field-type hint catalog extraction, selected in `da2eac26` and
implemented in `bc19058a`. `schema.ex` moved from 4,614 to 3,818 lines.

Next candidate:
Implement and verify the selected artifact-validation router, then re-rank the
remaining JSON-schema property dispatch and schema-builder blocks.

Blocked:
No.

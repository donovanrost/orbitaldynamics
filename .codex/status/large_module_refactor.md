# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema artifact-validation router extraction.

Status:
Implemented and verified.

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
- Added `OrbitalDynamics.Schema.ArtifactValidationRouter` as the owner of all
  122 specialized validation routes plus the generic required-field fallback.
- Routed `ArtifactValidation` through the new owner while preserving the public
  `Schema` facade.
- Removed validation-only aliases, contract attributes, and primitive imports
  from the facade after confirming its remaining runtime dependencies.
- `schema.ex` moved from 3,818 to 3,194 lines; the new owner is 638 lines.

Verification:
- Strict focused/broad schema and validation suite: 359 tests passed.
- AST-normalized old/new route comparison: 122/122 clauses matched exactly,
  including order, literal identities, bodies, and fallback.
- Full schema export regenerated 121 contract schemas and the bundle with no
  checked-in schema diff.
- `mix xref trace` confirms the intended runtime edge from `Schema` to
  `ArtifactValidationRouter.validate/3`.
- Formatting, `git diff --check`, and bounded source/schema diff review passed.
- Strict compile passed for 4,093 files with warnings as errors.

Behavior/schema changes:
None intended. Clause order, owner calls, contract identities, required-field
fallback, issue paths and ordering, public `Schema`, validation results, and
checked-in exports must remain unchanged.

Last completed slice:
Schema artifact-validation router extraction, selected in `49196371` and
implemented in `2b8aebb6`. `schema.ex` moved from 3,818 to 3,194 lines.

Next candidate:
Re-rank the remaining JSON-schema property dispatch and schema-builder blocks,
favoring a cohesive boundary whose dependencies can be expressed without
moving public facade ownership or coupling a new owner back to private state.

Blocked:
No.

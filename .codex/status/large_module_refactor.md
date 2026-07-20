# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Cadence review property-provider deduplication.

Status:
Completed and verified.

Selected boundary:
Move the duplicated cadence-import-manifest and cadence-source-review
property-provider assemblies from the public `Schema` facade into a shared
`CadenceReviewSchemaProviders` owner. Preserve the identical 13-key order while
passing facade-owned readiness/resource/handoff properties as explicit
callbacks.

Selection evidence:
- The public `Schema` facade remains 1,391 lines.
- The two private property-provider functions are structurally identical and
  each is used by only its corresponding cadence row builder.
- Branch-scoped, authority, and resource-variance properties already have
  focused direct owners.
- The remaining facade-owned property families can preserve laziness through
  explicit callbacks.

Implementation:
Selected in `82c6235b` and implemented in `2c854a8c`. Added the 39-line
`CadenceReviewSchemaProviders` owner and replaced two identical private
property-provider assemblies with one shared facade wiring point. The public
`Schema` facade moved from 1,391 to 1,349 lines.

Verification:
- Exact comparison passed for all 13 ordered property-provider keys and
  outputs, including ten callback-backed families.
- Focused schema/validation suite passed: 359 tests.
- Full checked-in schema export regenerated with no diff.
- Runtime xref shows one direct `Schema` -> `CadenceReviewSchemaProviders` edge.
- Strict forced compile passed with warnings as errors: 4,121 files.
- `JsonSchemaPropertyRouter` remains an ordered 76-head facade.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Cadence review property-provider deduplication, selected in `82c6235b` and
implemented in `2c854a8c`. The public `Schema` facade moved from 1,391 to 1,349
lines.

Next candidate:
Consolidate the two remaining cadence row/schema-provider assemblies in the
shared owner while preserving their small manifest/source-review differences.

Blocked:
No.

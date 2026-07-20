# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema validation/migration/lint operations context extraction.

Status:
Selected; implementation pending.

Selected boundary:
Add SchemaOperationsValidation owner-default entry points for schema validation
report/batch, schema migration report, campaign request lint, and study
manifest lint artifacts. Derive requirements from ValidationRegistryContracts
and LintRegistryContracts, route all five direct Schema clauses, and keep every
contract API unchanged.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,888 lines; the other
  targeted public facades are now 164 to 524 lines.
- Five adjacent administrative clauses repeat required-field setup and routing.
- ValidationRegistryContracts and LintRegistryContracts own every requirement.
- ValidationReportContracts, SchemaMigrationContracts, and LintContracts own
  all artifact-specific validation.
- No route needs callbacks, recursive Schema lookup, or facade-local context.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, validation ordering and paths, public Schema
APIs, validation results, and checked-in exports must remain unchanged.

Last completed slice:
Schema model-capability validation context extraction, selected in `c49cbd4f`
and implemented in `6f7789aa`.
`schema.ex` moved from 4,896 to 4,888 lines.

Next candidate:
Implement and verify the selected schema operations context extraction, then
re-rank the remaining Schema responsibility clusters.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema validation/migration/lint operations context extraction.

Status:
Completed and pushed.

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
Added `SchemaOperationsValidation` as the registry-backed family owner for the
five selected artifacts and routed their direct `Schema` validation clauses
through it. `schema.ex` moved from 4,888 to 4,864 lines.

Verification:
- Strict focused baseline: 8 tests passed.
- Focused plus adjacent validation coverage after extraction: 26 tests passed.
- Full schema export completed with no checked-in artifact changes.
- Static routing review found exactly the five intended direct facade routes.
- `mix xref graph` found only the expected runtime caller from `schema.ex`.
- Formatting and `git diff --check` passed.
- Strict forced compile passed across 4,080 files with warnings as errors.
- Bounded diff review confirmed registry-owned requirements, contract routing,
  validation ordering, and validation paths remain unchanged.
- Implementation committed and pushed as `fdda4147`.

Behavior/schema changes:
None. Required fields, validation ordering and paths, public Schema APIs,
validation results, and checked-in exports remain unchanged.

Last completed slice:
Schema validation/migration/lint operations context extraction, selected in
`3f36e8da` and implemented in `fdda4147`.
`schema.ex` moved from 4,888 to 4,864 lines.

Next candidate:
Re-rank the remaining Schema responsibility clusters and select the next
facade-preserving extraction.

Blocked:
No.

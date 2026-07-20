# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema validation-reference/acceptance context extraction.

Status:
Selected; implementation pending.

Selected boundary:
Add ValidationArtifactValidation owner-default entry points for validation
reference fixtures/reports/checks, validation records, model acceptance
reports, and safety-case summaries. Derive requirements from the validation
and acceptance registries and model limits from ValidationCapabilityContext,
then route all six direct Schema clauses. Keep artifact contract APIs unchanged.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,958 lines; the other
  targeted public facades are now 164 to 524 lines.
- Six direct clauses repeat registry requirements and family owner routing.
- ValidationRegistryContracts and ValidationAcceptanceRegistryContracts own
  every required-field definition.
- ValidationCapabilityContext owns the acceptance-report model limits.
- ValidationReferenceContracts, ValidationRecordContracts, and
  ValidationAcceptanceReportContracts own all artifact-specific validation.
- No route needs recursive Schema lookup or facade-local callbacks.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, model limits, validation ordering and paths,
public Schema APIs, validation results, and checked-in exports must remain
unchanged.

Last completed slice:
Schema timeline-artifact validation context extraction, selected in `f2d5e2df`,
inventory-corrected in `67c69b6f`, and implemented in `e84783b5`.
`schema.ex` moved from 5,034 to 4,958 lines.

Next candidate:
Implement and verify the selected validation-reference/acceptance context
extraction, then re-rank the remaining Schema responsibility clusters.

Blocked:
No.

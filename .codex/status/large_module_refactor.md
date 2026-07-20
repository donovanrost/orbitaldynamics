# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema validation-reference/acceptance context extraction.

Status:
Completed and pushed.

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
Added ValidationArtifactValidation with one two-registry-backed entry point,
full-contract fixture routing, preserved reference report/check required-field
ordering, record validation, and acceptance model-limit context. Routed all six
direct Schema clauses to the owner. `schema.ex` moved from 4,958 to 4,939 lines.

Verification:
- Strict validation evidence/scoring baseline before extraction: 11 passed.
- The same strict focused suite after extraction: 11 passed.
- Strict validation fixture, acceptance, operator-review, candidate-refresh,
  and campaign coverage: 52 passed.
- The full schema-export task completed and produced no checked-in changes.
- Exact static inspection confirms six direct owner routes and no remaining
  facade-local validation-reference/acceptance logic.
- `mix xref callers OrbitalDynamics.Schema.ValidationArtifactValidation`
  reports only the expected Schema facade runtime caller.
- `mix format --check-formatted` and `git diff --check` passed.
- Strict forced compile passed across 4,077 files with no warnings.
- Bounded local review confirmed full fixture contract input, registry
  requirements, duplicate reference required-field ordering, model limits, and
  issue paths are preserved.
- Implementation commit `f71e1160` pushed to `main`.

Behavior/schema changes:
None. Required fields, model limits, validation ordering and paths, public
Schema APIs, validation results, and checked-in exports remain unchanged.

Last completed slice:
Schema validation-reference/acceptance context extraction, selected in
`f8ce79ba` and implemented in `f71e1160`.
`schema.ex` moved from 4,958 to 4,939 lines.

Next candidate:
Re-rank the remaining Schema responsibility clusters. Preserve the
context-bearing CommonJsonSchema wrappers unless a separate exact ownership
boundary is proven.

Blocked:
No.

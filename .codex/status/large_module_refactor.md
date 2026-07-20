# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Source-evidence schema-provider extraction.

Status:
Completed and verified.

Selected boundary:
Move the source-evidence, readiness/quality source-report, freshness,
schema-validation, and execution-report evidence builders plus their dependency
assemblers from the public `Schema` facade into a new
`SourceEvidenceSchemaProviders` owner. Build one lazy evidence context and pass
its closures to the operator/cadence owners.

Selection evidence:
- The public `Schema` facade remains 1,216 lines.
- All six evidence builders are consumed only as callbacks by the extracted
  operator/cadence schema-provider owners.
- The builders share one stable-ID/battery-handoff dependency context, with
  quality-gate evidence adding only common count-map fragments.
- Status enums and evidence shape construction already have focused direct
  owners.

Implementation:
Selected in `b9b5302f` and implemented in `30b37935`. Added the 61-line
`SourceEvidenceSchemaProviders` owner with six lazy evidence closures and one
shared stable-ID/battery dependency context, then passed those closures to the
operator/cadence owners. The public `Schema` facade moved from 1,216 to 1,176
lines.

Verification:
- Exact comparison passed for all six evidence-provider keys and outputs using
  sentinel battery-handoff properties.
- Focused schema/validation suite passed: 359 tests.
- Full checked-in schema export regenerated with no diff.
- Runtime xref shows one direct `Schema` -> `SourceEvidenceSchemaProviders`
  edge.
- Strict forced compile passed with warnings as errors: 4,122 files.
- `JsonSchemaPropertyRouter` remains an ordered 76-head facade.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Source-evidence schema-provider extraction, selected in `b9b5302f` and
implemented in `30b37935`. The public `Schema` facade moved from 1,216 to 1,176
lines.

Next candidate:
Re-rank the remaining public-facade provider clusters and select the next
bounded extraction.

Blocked:
No.

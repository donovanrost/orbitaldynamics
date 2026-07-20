# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Source-evidence schema-provider extraction.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Cadence review row schema-provider completion, selected in `b23e0d78` and
implemented in `9b951825`. The public `Schema` facade moved from 1,349 to 1,216
lines.

Next candidate:
Implement and verify the selected source-evidence provider extraction, then
re-rank the remaining public-facade clusters.

Blocked:
No.

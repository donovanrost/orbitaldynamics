# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation schema-provider extraction.

Status:
Selected; implementation pending.

Selected boundary:
Move the validation-record, model-acceptance-row, safety-case-evidence-row,
and validation-reference-report provider builders from the public `Schema`
facade into a new `ValidationSchemaProviders` owner. Merge its lazy provider
map into the existing property context.

Selection evidence:
- The public `Schema` facade remains 1,917 lines.
- These four contiguous private builders are referenced only by the property
  provider registry, apart from model acceptance's local reuse of the
  validation-record builder.
- They form a cohesive validation-schema boundary and depend only on the
  stable-ID pattern plus `ValidationJsonSchema` primitives.
- A provider-map owner preserves lazy evaluation and removes both registry
  entries and implementation details from the public facade.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Planning-analysis schema-provider extraction, selected in `bb50e34c` and
implemented in `e765efdb`. The public `Schema` facade moved from 1,959 to 1,917
lines.

Next candidate:
Implement and verify the selected validation provider extraction, then
re-rank the remaining public-facade provider clusters.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Cadence review property-provider deduplication.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Operator-review row schema-provider completion, selected in `0d1049c0` and
implemented in `b238573d`. The public `Schema` facade moved from 1,443 to 1,391
lines.

Next candidate:
Implement and verify the shared cadence property-provider extraction, then
assess consolidation of the two remaining row/schema-provider assemblies.

Blocked:
No.

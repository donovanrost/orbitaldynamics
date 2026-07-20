# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline core schema-provider extraction.

Status:
Selected; implementation pending.

Selected boundary:
Move timeline identity, link, protection, uncertainty, activity-context,
candidate-source-window, cadence-import, preservation-source, and protection-
summary builders from the public `Schema` facade into a new
`TimelineCoreSchemaProviders` owner. Merge its lazy registry providers and
route remaining facade/report dependencies through public focused helpers.

Selection evidence:
- The public `Schema` facade remains 1,126 lines.
- Six builders are registry providers and the three remaining helpers feed only
  activity/report schema composition.
- The cluster is self-contained around the stable-ID pattern, common fragments,
  and `TimelineContextJsonSchema`.
- Public focused helpers can preserve lazy callback timing for downstream
  owners without facade wrappers.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Activity schema-provider extraction, selected in `d1cb94a8` and implemented in
`b2143653`. The public `Schema` facade moved from 1,161 to 1,126 lines.

Next candidate:
Implement and verify the selected timeline core extraction, then assess the
remaining callback-heavy timeline report layer.

Blocked:
No.

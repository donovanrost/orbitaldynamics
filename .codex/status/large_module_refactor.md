# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline-context JSON Schema extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract timeline identity, provenance, throughput derivation, execution
uncertainty, protection/lifecycle/link, protection-summary, and activity-context
JSON Schema construction into
`OrbitalDynamics.Schema.TimelineContextJsonSchema`. Preserve the existing
private Schema helper seams.

Selection evidence:
- `schema.ex` is 6,861 lines; the selected JSON Schema family spans
  3,870-3,940 and 3,950-3,995.
- The cluster has one responsibility: construct reusable timeline/activity
  context schemas consumed by operational timeline, diff, review, and import
  schema exporters.
- Stable-ID, collection, probability, and numeric-triplet primitives remain
  facade-owned inputs; timeline-preservation source construction remains
  outside this boundary.
- Registry data, JSON Schema export, contract dispatch, unrelated validation,
  and all public `Schema` APIs remain outside.

Verification:
Pending: focused timeline/activity schema baselines, exact old/new JSON Schema
documents, strict compile, broader Schema contract tests, JSON Schema export
checks, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema optional operational-readiness validation consolidation, selected in
`38190e37` and implemented in `d8568e86`. `schema.ex` moved from 6,872 to 6,861
lines; the existing owner moved from 216 to 234 lines.

Next candidate:
Re-inventory remaining Schema families after timeline-context JSON Schema
construction has one production owner.

Blocked:
No.

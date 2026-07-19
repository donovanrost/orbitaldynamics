# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline-context JSON Schema extraction.

Status:
Completed and published.

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
- Strict compile passed across 3,870 files with warnings as errors.
- Focused JSON Schema export, operational-timeline, and activity-state contracts
  passed: 26 tests, including all 15 export contracts.
- Full Schema suite passed: 175 tests.
- Exact old/new JSON Schema documents matched for 10 timeline, review,
  execution, campaign, candidate, transition, and lifecycle contracts.
- Static inspection confirms the facade retains only reusable helper seams and
  the orphaned provenance helper was removed; runtime xref reports `Schema` as
  the sole caller of the new owner.
- `git diff --check` and bounded ownership review passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema timeline-context JSON Schema extraction, selected in `a3b0ad64` and
implemented in `b082045f`. `schema.ex` moved from 6,861 to 6,786 lines; the
dedicated owner is 124 lines.

Next candidate:
Re-inventory remaining Schema families after timeline-context JSON Schema
construction has one production owner.

Blocked:
No.

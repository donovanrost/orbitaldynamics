# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline-source validation extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract optional timeline diff, dependency-impact, activity-precondition,
integrity, preservation, lifecycle, and activity-state source validation into
`OrbitalDynamics.Schema.TimelineSourceValidation`. Preserve the existing
private `Schema` callback seams as thin delegates.

Selection evidence:
- `schema.ex` is 7,204 lines; the selected contiguous cluster spans
  6,183-6,337.
- The cluster has one responsibility: validate optional timeline-family source
  artifacts embedded in handoff and summary rows.
- Its dependencies are existing timeline contract modules, primitive errors,
  and capability-derived timeline/timeline-feedback model limits.
- Transition-application validation, registry data, JSON Schema export,
  contract dispatch, and all public `Schema` APIs remain outside.

Verification:
Pending: focused timeline-summary and activity-state baselines, exact old/new
fixture validation reports, strict compile, broader Schema contract tests,
schema export checks, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema operational-readiness validation extraction, selected in `30c29dfa` and
implemented in `9577045d`. `schema.ex` moved from 7,293 to 7,204 lines; the
dedicated owner is 216 lines.

Next candidate:
Re-inventory remaining Schema transition-application and family-validation
clusters after timeline-source validation has one production owner.

Blocked:
No.

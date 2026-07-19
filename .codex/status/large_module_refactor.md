# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext timeline-lifecycle-state extraction.

Status:
Completed and pushed.

Selected boundary:
Extract timeline-lifecycle-state risk filtering, string-key normalization,
scalar/map/list context projection, nil removal, stable first-seen
deduplication, and non-list fallback into
`OrbitalDynamics.RecommendationRiskContext.TimelineLifecycleState`. Preserve
the public RecommendationRiskContext function as a delegate.

Selection evidence:
- Live re-ranking places `recommendation_risk_context.ex` at 2,521 lines, the
  largest eligible facade behind Schema, Timeline, MissionPlan.Activity, and
  the root public facade.
- The selected public family spans lines 1,276-1,381 and exclusively owns the
  timeline-lifecycle-state predicate plus its 35-field projection.
- Production consumers call only the public facade from operator-review and
  Cadence-import strategy recommendation contexts.
- Context-key declarations, neighboring publication/activity-lifecycle/
  dependency projections, shared facade helpers, public names, and artifact
  contracts remain outside this boundary.
- Existing type-or-feedback-scope selection, atom-key normalization,
  scalar-versus-list field semantics, nil/empty omission, first-seen ordering,
  deduplication, non-list fallback, and exact output keys must remain
  unchanged.

Implementation:
- Selection was recorded and pushed in `94b78264`.
- Implementation was committed and pushed in `8019fcad`.
- `recommendation_risk_context.ex` moved from 2,521 to 2,417 lines.
- `OrbitalDynamics.RecommendationRiskContext.TimelineLifecycleState` is a
  139-line owner reached through the unchanged public facade function.

Verification:
- Strict warning-clean compilation passed across 3,962 files.
- The focused strategy pressure regression and four adjacent lifecycle
  source/review/replay files passed together: 23 tests.
- Exact old/new public parity passed for 8 cases covering empty/non-list
  inputs, unrelated risks, type/scope selection, atom/string keys,
  scalar/map/nested-list fields, nil removal, stable deduplication, and
  ordering.
- `mix xref callers` reports only the RecommendationRiskContext facade; the
  compile-connected graph reports the new owner and facade.
- The removed projection body is absent from the facade, formatting and
  `git diff --check` passed, and the final diff is ownership-only.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext timeline-lifecycle-state extraction, selected in
`94b78264` and implemented in `8019fcad`.
`recommendation_risk_context.ex` moved from 2,521 to 2,417 lines; the dedicated
timeline-lifecycle-state owner is 139 lines.

Next candidate:
Re-rank the live checkout and select the next cohesive facade-preserving
boundary.

Blocked:
No.

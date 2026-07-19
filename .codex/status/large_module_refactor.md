# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext timeline-publication extraction.

Status:
Completed and pushed.

Selected boundary:
Extract timeline-publication risk filtering, string-key normalization, context
projection, nested-list flattening, nil removal, and stable first-seen
deduplication into
`OrbitalDynamics.RecommendationRiskContext.TimelinePublication`. Preserve both
public RecommendationRiskContext clauses as delegates to the dedicated owner.

Selection evidence:
- Live re-ranking places `recommendation_risk_context.ex` at 2,607 lines, the
  largest eligible facade behind Schema, Timeline, MissionPlan.Activity, and
  the root public facade.
- The selected public family spans lines 1,273-1,360 and exclusively owns the
  timeline-publication risk predicate plus its 29-field projection.
- Production consumers call only the public facade from operator-review and
  Cadence-import strategy recommendation contexts.
- Neighboring timeline preservation/lifecycle/dependency contexts, context-key
  declarations, shared facade helpers, public names and result contracts
  remain outside this boundary.
- Existing type-or-feedback-scope selection, atom-key normalization,
  scalar-versus-list field semantics, nil/empty omission, first-seen ordering,
  deduplication, non-list fallback, and exact output keys must remain
  unchanged.

Implementation:
- Selection was recorded and pushed in `6d4b0888`.
- Implementation was committed and pushed in `d3e26bb2`.
- `recommendation_risk_context.ex` moved from 2,607 to 2,521 lines.
- `OrbitalDynamics.RecommendationRiskContext.TimelinePublication` is a
  121-line owner reached through the unchanged public facade function.

Verification:
- Strict warning-clean compilation passed across 3,959 files.
- The focused strategy pressure regression and three adjacent
  timeline-publication/direct-consumer files passed together: 7 tests.
- Exact old/new public parity passed for 8 cases covering empty/non-list
  inputs, unrelated risks, type/scope selection, atom/string keys,
  scalar/nested-list fields, nil removal, stable deduplication, and ordering.
- `mix xref callers` reports only the RecommendationRiskContext facade; the
  compile-connected graph reports the new owner and facade.
- The removed projection body is absent from the facade, formatting and
  `git diff --check` passed, and the final diff is ownership-only.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext timeline-publication extraction, selected in
`6d4b0888` and implemented in `d3e26bb2`.
`recommendation_risk_context.ex` moved from 2,607 to 2,521 lines; the dedicated
timeline-publication owner is 121 lines.

Next candidate:
Re-rank the live checkout and select the next cohesive facade-preserving
boundary.

Blocked:
No.

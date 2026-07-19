# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext timeline-publication extraction.

Status:
Selected; implementation not started.

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

Verification plan:
- Run the strict warning-clean compile before and after implementation.
- Run the focused strategy recommendation pressure/context regressions and
  adjacent operator-review and Cadence-import consumers.
- Run exact old/new public parity from this selection commit across atom/string
  keys, type/scope selection, scalar/nested-list fields, duplicates, nils,
  unrelated risks, empty/non-list inputs, deterministic output, and public
  errors.
- Run `mix xref callers` for the new owner, inspect compile-connected
  dependents, check formatting and `git diff --check`, prove the removed
  projection family is absent from the facade, and review final facade/owner
  boundaries.

Behavior/schema changes:
None intended.

Last completed slice:
TimelineFeedback operational-feedback exclusion extraction, selected in
`cb84add9` and implemented in `9ce4d7bb`. `timeline_feedback.ex` moved from
2,608 to 2,472 lines; the dedicated exclusion owner is 142 lines.

Next candidate:
Implement and verify the selected RecommendationRiskContext
timeline-publication extraction.

Blocked:
No.

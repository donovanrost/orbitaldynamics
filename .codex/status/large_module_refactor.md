# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext timeline-lifecycle-state extraction.

Status:
Selected; implementation not started.

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

Verification plan:
- Run the strict warning-clean compile before and after implementation.
- Run the focused strategy recommendation pressure regression and adjacent
  timeline-lifecycle operator-review, Cadence-import, and replay consumers.
- Run exact old/new public parity from this selection commit across atom/string
  keys, type/scope selection, scalar/map/nested-list fields, duplicates, nils,
  unrelated risks, empty/non-list inputs, deterministic output, and public
  errors.
- Run `mix xref callers` for the new owner, inspect compile-connected
  dependents, check formatting and `git diff --check`, prove the removed
  projection family is absent from the facade, and review final facade/owner
  boundaries.

Behavior/schema changes:
None intended.

Last completed slice:
LinkCapacity station-availability extraction, selected in `824e5611` and
implemented in `f2c45f2e`. `communications/link_capacity.ex` moved from 2,554
to 2,462 lines; the dedicated station-availability owner is 116 lines.

Next candidate:
Implement and verify the selected RecommendationRiskContext
timeline-lifecycle-state extraction.

Blocked:
No.

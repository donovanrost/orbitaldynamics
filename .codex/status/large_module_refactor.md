# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactContention resolution-summary values extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract resolution-summary selected/deferred/review ID projection, grouped
value/list routing, grouped review-contact routing, field counts, stable
nil-removing deduplication, sorting, and empty-group omission into
`OrbitalDynamics.Communications.ContactContention.ResolutionSummaryValues`.
Preserve all public ContactContention report and summary facades.

Selection evidence:
- Live re-ranking places `communications/contact_contention.ex` at 2,509
  lines, the largest eligible facade behind Schema, Timeline,
  MissionPlan.Activity, and the root public facade.
- The selected helper family spans lines 711-778 and exclusively owns
  deterministic recommendation value/list/count projection for resolution
  summaries.
- Resolution-summary construction consumes seven helpers; capacity-demand
  source routing consumes the stable compact-list primitive once.
- Capacity-demand arithmetic, contention grouping, recommendation selection,
  resolution policy, approval requirements, provider/station evidence, public
  clauses, and artifact contracts remain outside this boundary.
- Existing selected/deferred/duplicate inclusion, nil/group omission,
  flattening, deduplication, lexicographic sorting, frequency counts, exact
  routing keys, and deterministic output must remain unchanged.

Verification plan:
- Run the strict warning-clean compile before and after implementation.
- Run the focused ContactContention regression file and adjacent resolution
  review/import/replay/schema consumers selected from live references.
- Run exact old/new public parity from this selection commit across selected,
  deferred, duplicate, ambiguous, review, grouped resource/action/reason
  routes, nil/empty groups, duplicate values, ordering, deterministic
  summaries, and public errors.
- Run `mix xref callers` for the new owner, inspect compile-connected
  dependents, check formatting and `git diff --check`, prove the removed
  helper family is absent from the facade, and review final facade/owner
  boundaries.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext timeline-lifecycle-state extraction, selected in
`94b78264` and implemented in `8019fcad`.
`recommendation_risk_context.ex` moved from 2,521 to 2,417 lines; the dedicated
timeline-lifecycle-state owner is 139 lines.

Next candidate:
Implement and verify the selected ContactContention resolution-summary values
extraction.

Blocked:
No.

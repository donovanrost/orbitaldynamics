# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext contact-intent extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract the contact-intent risk-context key contract, downlink-completion-gap
predicate, atom-key normalization, value aggregation, and context projection
into `OrbitalDynamics.RecommendationRiskContext.ContactIntent`. Preserve the
public RecommendationRiskContext facade through direct key/context delegates.

Selection evidence:
- Live re-ranking places `recommendation_risk_context.ex` at 2,748 lines,
  fourth behind Schema, Timeline, and MissionPlan.Activity, and ahead of
  TimelineFeedback, StationCalendar, LinkCapacity, and ContactContention.
- The selected family owns 38 contact-intent context keys, the contact-intent
  downlink-completion-gap predicate, contact-intent filtering, atom-key
  normalization, scalar/list value aggregation, nil omission, and context-map
  construction.
- Only the public `contact_intent_context_keys/0` and
  `contact_intent_context/1` facade functions consume this responsibility.
- Other risk families, shared facade context helpers, public contracts, and
  recommendation assembly remain outside this boundary.
- Existing input-order uniqueness, first-seen ordering, scalar versus list
  flattening, atom-key normalization, exact predicate matching, nil/empty
  omission, invalid-input fallback, and output keys must remain unchanged.

Verification plan:
- Run the strict warning-clean compile before and after implementation.
- Run the focused RecommendationRiskContext regression file and adjacent
  contact-intent/recommendation consumers selected from live references.
- Run exact old/new parity from this selection commit across string/atom keys,
  type/risk_type predicates, scalar/list values, duplicates, unrelated risks,
  empty/invalid inputs, deterministic ordering, and full key contracts.
- Run `mix xref callers` for the new owner, inspect compile-connected
  dependents, check formatting and `git diff --check`, prove the removed
  helper family is absent from the facade, and review final facade/owner
  boundaries.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness evidence-normalization extraction, selected in
`a361cea1`, implemented in `c8501c35`, and handed off in `f721f395`.
`operational_readiness.ex` moved from 2,766 to 2,500 lines; the dedicated
evidence-normalization owner is 312 lines.

Next candidate:
Implement and verify the selected RecommendationRiskContext contact-intent
extraction.

Blocked:
No.

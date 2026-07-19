# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext contact-intent extraction.

Status:
Completed and pushed in `f7b9a0d0`.

Selected boundary:
Extract the contact-intent risk-context key contract, downlink-completion-gap
predicate, atom-key normalization, value aggregation, and context projection
into `OrbitalDynamics.RecommendationRiskContext.ContactIntent`. Preserve the
public RecommendationRiskContext facade through direct key/context delegates.

Selection evidence:
- Live re-ranking placed `recommendation_risk_context.ex` at 2,748 lines,
  fourth behind Schema, Timeline, and MissionPlan.Activity, and ahead of
  TimelineFeedback, StationCalendar, LinkCapacity, and ContactContention.
- The extracted family owns 38 contact-intent context keys, the contact-intent
  downlink-completion-gap predicate, contact-intent filtering, atom-key
  normalization, scalar/list value aggregation, nil omission, and context-map
  construction.
- Only the public `contact_intent_context_keys/0` and
  `contact_intent_context/1` facade functions consume this responsibility.
- Other risk families, shared facade context helpers, public contracts, and
  recommendation assembly remain outside this boundary.

Verification:
- Strict warning-clean compile passed across 3,957 files:
  `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force --warnings-as-errors`.
- Focused contact-intent pressure regressions passed 13 tests; adjacent
  contact-intent candidate-refresh replay and recommendation-explanation
  consumers passed 24 tests. The final consolidated run passed all 37 tests.
- Exact old/new parity passed 8 comparisons from selection commit `3ba6891a`
  with `/tmp/recommendation_contact_intent_compare.exs`, covering the complete
  key contract, string/atom keys, type/risk_type predicates, scalar/list
  values, duplicates, first-seen ordering, unrelated risks, empty risks, and
  invalid-input fallback.
- `mix xref callers
  OrbitalDynamics.RecommendationRiskContext.ContactIntent` reports only the
  RecommendationRiskContext facade.
- Compile-connected xref scope for the new owner does not expand beyond the
  owner itself.
- Focused formatting, `git diff --check`, removed-family static checks, and
  final facade/owner review passed.

Behavior/schema changes:
None. The public RecommendationRiskContext facade, key contract, predicate,
atom-key normalization, scalar/list flattening, first-seen uniqueness, nil
omission, deterministic output, and invalid-input fallback are unchanged.

Last completed slice:
RecommendationRiskContext contact-intent extraction, selected in `3ba6891a`
and implemented in `f7b9a0d0`.
`recommendation_risk_context.ex` moved from 2,748 to 2,607 lines; the dedicated
contact-intent owner is 178 lines.

Next candidate:
Re-rank the live largest-module inventory and select the next cohesive,
facade-preserving ownership boundary.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext contact-allocation extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract the contact-allocation risk-context key contract, allocation-risk
filtering, atom-key normalization, multi-key/list flattening, stable
deduplication, and sparse context construction into
`OrbitalDynamics.RecommendationRiskContext.ContactAllocation`. Preserve
`contact_allocation_context_keys/0`, `contact_allocation_context/1`, and all
other RecommendationRiskContext public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `recommendation_risk_context.ex` at 2,142 lines,
  the largest ordinary eligible facade behind Schema, Timeline, and
  MissionPlan.Activity.
- RecommendationRiskContext already has eleven extracted context-family
  owners; the contact-allocation family remains in the facade with its key
  contract at lines 353-390 and builder at lines 1,417-1,502.
- The selected boundary mirrors existing ContactIntent and ResourceProjection
  owners: one public key contract, one context builder, one scope predicate,
  and private value/key normalization.
- Approval, contention, filter, station, timeline, objective, resource,
  maneuver, execution, feedback, and all other risk-context families remain
  outside the boundary.
- Exact key ordering, contact-allocation scope filtering, atom/string input
  parity, list flattening, first-seen value ordering, deduplication, empty-field
  omission, and non-list fallback must remain unchanged.

Implementation:
Pending.

Verification:
Pending strict focused baseline, exact old/new public parity, focused and
adjacent tests, static ownership checks, xref, strict warning-clean compile,
formatting, and diff checks.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness resource-availability evidence extraction, selected in
`d5786ac1` and implemented in `efb06679`.
`operational_readiness.ex` moved from 2,186 to 2,018 lines; the dedicated
resource-availability evidence owner is 215 lines.

Next candidate:
Complete the selected RecommendationRiskContext contact-allocation extraction.

Blocked:
No.

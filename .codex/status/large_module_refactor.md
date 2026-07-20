# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactIntent summary projection extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract contact-intent capacity-demand summary construction, direction/station
routing, required-capacity aggregation, row-derived counts, and deterministic
ID grouping into `OrbitalDynamics.Communications.ContactIntent.Summary`.
Preserve all ContactIntent and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `communications/contact_intent.ex` at 1,785 lines, the
  largest ordinary eligible facade.
- ContactIntent currently delegates only capacity evidence and provider-result
  interpretation, while summary construction remains inline at lines 277-537.
- The selected block has one responsibility: derive the compact summary and its
  capacity/direction/station routing solely from supplied intent rows.
- Activity normalization, intent construction, policy decisions, station
  calendar interpretation, identity validation, and all public contracts remain
  outside the boundary.
- Exact capacity-context precedence, direction aliases, totals, source counts,
  nested routing maps, ID sorting, empty-map omission, assumptions, public
  output, idempotent summary handling, and error behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
ResourceProjection approval-policy handoff extraction, selected in `3e1457c7`
and implemented in `2166062a`.
`resource_projection.ex` moved from 1,789 to 1,578 lines; the dedicated
ApprovalPolicy owner is 220 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `communications/contact_intent.ex` is now the largest ordinary
eligible facade at 1,785 lines, followed by RecommendationRiskContext and
OperationalReadiness.

Blocked:
No.

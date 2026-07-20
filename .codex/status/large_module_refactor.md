# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ResourceProjection approval-policy handoff extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract optional policy application for projected resource rows, invalid
activity inputs, and invalid resource-summary inputs plus construction of their
approval requirements into
`OrbitalDynamics.ResourceProjection.ApprovalPolicy`.
Preserve all ResourceProjection and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `resource_projection.ex` at 1,789 lines, the
  largest ordinary eligible facade.
- ResourceProjection already delegates nine focused responsibilities, while
  optional policy decisions and approval requirement construction remain inline
  at lines 1,060-1,268.
- The selected block has one responsibility: attach deterministic approval
  policy handoff evidence to projected and invalid-input rows.
- Activity/summary normalization, projection math, flow construction, pressure
  classification, report assembly, and all public contracts remain outside the
  boundary.
- Exact risk routing, policy subjects, requirement IDs/actions/reasons/context,
  compaction, ordering, nil-policy behavior, policy decisions, public output,
  and error behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
TimelineFeedback operational-feedback aggregation extraction, selected in
`da283212` and implemented in `8d9a5204`.
`timeline_feedback.ex` moved from 1,797 to 1,546 lines; the dedicated
OperationalFeedbackSummary owner is 252 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `resource_projection.ex` is now the largest ordinary eligible
facade at 1,789 lines, followed by ContactIntent and RecommendationRiskContext.

Blocked:
No.

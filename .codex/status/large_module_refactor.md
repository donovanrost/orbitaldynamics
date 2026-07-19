# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness operator-training evidence extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract artifact/review/import operator-training evidence traversal,
role/training/certification/qualification alias resolution, stable string
normalization, deduplication/sorting, and requirement-count projection into
`OrbitalDynamics.OperationalReadiness.OperatorTrainingEvidence`. Preserve all
public OperationalReadiness report and summary facades.

Selection evidence:
- Live re-ranking places `operational_readiness.ex` at 2,385
  lines, the largest eligible facade behind Schema, Timeline,
  MissionPlan.Activity, and the root public facade.
- The selected helper family spans lines 1,876-1,984 and exclusively owns
  operator-training evidence collection and aggregation.
- Readiness evidence construction is the single consumer of the resulting
  training context.
- Quality-gate summary projection, training gate decisions, generic evidence
  normalization, shared stable-ID map routing, other evidence families, public
  clauses, and artifact contracts remain outside this boundary.
- Existing artifact-before-review-before-import traversal, nested source-row
  discovery, field-alias order, scalar/list wrapping, atom/string
  normalization, unsupported-value omission, deduplication, lexical sorting,
  positive-count omission, total counting, exact keys, and empty behavior must
  remain unchanged.

Implementation:
- Pending.

Verification:
- Pending focused baseline, strict compilation, exact old/new public parity,
  focused and adjacent tests, static ownership checks, and xref review.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext execution-success feedback extraction, selected in
`a4a79ea4` and implemented in `d0e3a58c`.
`recommendation_risk_context.ex` moved from 2,417 to 2,274 lines; the dedicated
execution-success feedback owner is 180 lines.

Next candidate:
Complete and verify the selected OperationalReadiness operator-training
evidence extraction.

Blocked:
No.

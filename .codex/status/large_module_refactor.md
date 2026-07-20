# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RecommendationRiskContext approval-boundary extraction.

Status:
Completed and pushed in `c443180c`.

Selected boundary:
Extract approval-boundary context keys, risk selection, and context projection
into `OrbitalDynamics.RecommendationRiskContext.ApprovalBoundary`. Preserve all
RecommendationRiskContext and downstream public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `recommendation_risk_context.ex` at 1,212 lines, the
  largest ordinary eligible facade.
- RecommendationRiskContext delegates nineteen focused risk families, while
  approval-boundary keys, risk selection, and projection remain inline at
  lines 26-40, 358, and 425-468.
- The selected code has one responsibility: identify approval-boundary risks
  by feedback scope or pressure type and project approval, authority, policy,
  review, and provenance context.
- Provider reservations, capacity packs, contention, filters, timelines, and
  all other risk families remain outside the boundary.
- Exact context key order, scope/type selection, atom-key normalization, list
  flattening, nil omission, value ordering, non-list behavior, public output,
  and error behavior must remain unchanged.

Implementation:
- Added `OrbitalDynamics.RecommendationRiskContext.ApprovalBoundary` as the
  focused owner of the ordered key contract, scope/type risk selection, atom
  key normalization, and approval, authority, policy, review, and provenance
  context projection.
- Preserved the public RecommendationRiskContext facade through delegates.
- All other risk families remain outside the extraction.
- `recommendation_risk_context.ex` moved from 1,212 to 1,153 lines; the
  dedicated ApprovalBoundary owner is 83 lines.

Verification:
- Focused baseline and post-change test passed normally; the file retains its
  two pre-existing signed-zero warnings.
- Exact old/new public parity: four results passed, covering ordered keys,
  atom-keyed rich context, both selection forms, unrelated-risk exclusion,
  empty input, and non-list input.
- Five adjacent recommendation tests passed with warnings treated as errors.
- Static ownership and xref checks passed; only the facade calls the extracted
  owner at runtime.
- Forced warning-clean test compile passed across 4,032 files.
- Focused formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext approval-boundary extraction, selected in
`0175af8b` and implemented in `c443180c`.
`recommendation_risk_context.ex` moved from 1,212 to 1,153 lines; the dedicated
ApprovalBoundary owner is 83 lines.

Next candidate:
After this slice, re-rank the live checkout. OperationalReadiness is the next
largest ordinary eligible facade.

Blocked:
No.

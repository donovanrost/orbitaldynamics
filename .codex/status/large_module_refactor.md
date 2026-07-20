# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ResourceFilter approval-policy extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract suppressed-candidate and invalid-resource-summary approval-policy
application, requirement projection, action classification, and risk evidence
into `OrbitalDynamics.ResourceFilter.ApprovalPolicy`.
Preserve all ResourceFilter and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `resource_filter.ex` at 1,542 lines, the
  largest ordinary eligible facade.
- ResourceFilter currently delegates candidate-input normalization and summary
  projection, while approval-policy application, requirement construction,
  action/type classification, and resource risk evidence remain inline at
  lines 908-1,168.
- The selected block has one responsibility: translate suppressed candidates
  and invalid resource summaries into policy requirements and attach
  deterministic decisions.
- Resource-summary normalization, candidate suppression decisions, row
  identity/disambiguation, summary projection, and all public contracts remain
  outside the boundary.
- Exact no-policy passthrough, policy IDs/status fields, requirement
  type/action/reason precedence, activity context and risk fields, direction
  classification, decision payloads, public output, and error behavior must
  remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
ContactContention approval-policy extraction, selected in `22b40f4f` and
implemented in `25b80862`.
`communications/contact_contention.ex` moved from 1,546 to 1,305 lines; the
dedicated ApprovalPolicy owner is 256 lines.

Next candidate:
After this slice, re-rank the live checkout. OperationalReadiness and
RecommendationRiskContext are the next largest ordinary eligible facades.

Blocked:
No.

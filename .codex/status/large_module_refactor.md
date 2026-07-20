# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ResourceFilter approval-policy extraction.

Status:
Completed and pushed in `7b057dbd`.

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
- Added `OrbitalDynamics.ResourceFilter.ApprovalPolicy` as the owner of
  suppressed-candidate and invalid-summary no-policy passthrough, policy
  decisions, requirement/action/type classification, risk projection, and
  activity-context evidence.
- Wired invalid-summary and suppressed-candidate report construction directly
  to the owner while preserving ResourceFilter and root APIs.
- Kept resource-summary normalization, candidate suppression decisions, row
  identity/disambiguation, blocking-dimension projection, and summary
  projection outside the boundary.
- `resource_filter.ex` moved from 1,542 to 1,310 lines; the new owner is 271
  lines.

Verification:
- Strict focused baseline passed all 37 ResourceFilter tests.
- Exact old/new public parity passed for four deterministic whole reports:
  policy-classified observation suppression, command-contact suppression,
  invalid resource summaries, and nil-policy report passthrough.
- Post-extraction focused and adjacent ResourceFilter, campaign-planner,
  candidate-refresh build/replay, operator-review, schema-contract, and
  validation verification passed all 71 tests.
- Static checks confirm approval application, requirement/action/type helpers,
  and resource risk projection left the facade; xref reports only
  ResourceFilter as a runtime caller.
- Strict warning-clean forced compile passed for 4,021 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
ResourceFilter approval-policy extraction, selected in `3dffbc73` and
implemented in `7b057dbd`.
`resource_filter.ex` moved from 1,542 to 1,310 lines; the dedicated
ApprovalPolicy owner is 271 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. OperationalReadiness is now the largest ordinary eligible facade at
1,541 lines, followed by RecommendationRiskContext.

Blocked:
No.

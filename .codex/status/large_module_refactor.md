# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactContention approval-policy extraction.

Status:
Completed and pushed in `25b80862`.

Selected boundary:
Extract group, invalid-input, and resolution-recommendation approval-policy
application and requirement projection into
`OrbitalDynamics.Communications.ContactContention.ApprovalPolicy`.
Preserve all ContactContention and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `communications/contact_contention.ex` at 1,546 lines,
  the
  largest ordinary eligible facade.
- ContactContention already delegates nine focused responsibilities, while
  approval-policy application and requirement construction remain inline at
  lines 845-1,080.
- The selected block has one responsibility: translate contention groups,
  blocked invalid inputs, and resolution recommendations into policy
  requirements and attach deterministic decisions.
- Contention grouping, annotation, recommendation selection/ranking, resolution
  policy parsing, summary projection, and all public contracts remain outside
  the boundary.
- Exact no-policy passthrough, policy IDs/status fields, requirement
  type/reason precedence, activity context fields and omission, feedback and
  station-calendar evidence, decision payloads, public output, and error
  behavior must remain unchanged.

Implementation:
- Added
  `OrbitalDynamics.Communications.ContactContention.ApprovalPolicy` as the owner
  of no-policy passthrough, group/invalid/recommendation policy decisions,
  requirement type/reason precedence, activity-context projection, and
  feedback/station-calendar evidence attachment.
- Wired contention-report and resolution-report construction directly to the
  three owner entry points while preserving ContactContention and root APIs.
- Kept contention grouping, annotation, recommendation selection/ranking,
  resolution-policy parsing, and summary projection outside the boundary.
- `contact_contention.ex` moved from 1,546 to 1,305 lines; the new owner is 256
  lines.

Verification:
- Strict focused baseline passed all 40 ContactContention tests.
- Exact old/new public parity passed for four deterministic whole artifacts:
  policy-classified contention groups, blocked invalid input, classified
  resolution recommendations, and nil-policy report passthrough.
- Post-extraction focused and adjacent ContactContention, campaign-planner,
  candidate-refresh replay/capability, operator-review, schema/export, and
  validation verification passed all 72 tests.
- Static checks confirm approval application, requirement construction, and
  direction-specific reason helpers left the facade; xref reports only
  ContactContention as a runtime caller.
- Strict warning-clean forced compile passed for 4,020 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
ContactContention approval-policy extraction, selected in `22b40f4f` and
implemented in `25b80862`.
`communications/contact_contention.ex` moved from 1,546 to 1,305 lines; the
dedicated ApprovalPolicy owner is 256 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. ResourceFilter is now the largest ordinary eligible facade at 1,542
lines, followed by OperationalReadiness and RecommendationRiskContext.

Blocked:
No.

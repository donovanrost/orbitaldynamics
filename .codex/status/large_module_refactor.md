# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactContention approval-policy extraction.

Status:
Selected; implementation not started.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness quality-gate summary extraction, selected in `85bc6b83`
and implemented in `0400f75b`.
`operational_readiness.ex` moved from 1,598 to 1,541 lines; the dedicated
QualityGateSummary owner is 132 lines.

Next candidate:
After this slice, re-rank the live checkout. ResourceFilter and
OperationalReadiness are the next largest ordinary eligible facades.

Blocked:
No.

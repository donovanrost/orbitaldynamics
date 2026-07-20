# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ResourceProjection approval-policy handoff extraction.

Status:
Completed and pushed in `2166062a`.

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
- Added `OrbitalDynamics.ResourceProjection.ApprovalPolicy` as the owner of
  optional policy application for projected resource rows, invalid activity
  inputs, invalid resource-summary inputs, and their approval requirements.
- Wired report assembly directly to the owner while preserving
  ResourceProjection and root public APIs.
- Kept activity/summary normalization, projection math, flow construction, and
  pressure classification in their existing owners.
- `resource_projection.ex` moved from 1,789 to 1,578 lines; the new owner is 220
  lines.

Verification:
- Strict focused baseline passed all 49 ResourceProjection tests.
- Exact old/new public parity passed for four deterministic report results:
  projected pressure with policy, invalid activity with policy, invalid summary
  with policy, and projected pressure without policy.
- Post-extraction focused and adjacent ResourceProjection, operator-review,
  strategy pressure/source-report, and validation-fixture verification passed
  all 61 tests.
- Static checks confirm the approval-policy helper family left the facade; xref
  reports only ResourceProjection as a runtime caller.
- Strict warning-clean forced compile passed for 4,009 files.
- Formatting and `git diff --check` passed.

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

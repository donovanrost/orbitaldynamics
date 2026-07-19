# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactAllocation approval-policy ownership extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract allocation policy-boundary detection, approval decisions,
requirements, command/health-check classification, and policy context
projection into
`OrbitalDynamics.Communications.ContactAllocation.ApprovalPolicy`. Preserve
the existing allocation/report facade.

Selection evidence:
- Live re-ranking places `communications/contact_allocation.ex` at 3,984 lines,
  ahead of TimelineFeedback and Manifest and behind the three larger
  orchestration-heavy facades.
- The selected policy projection has one facade entry point and forms one
  approval-review responsibility.
- Contact normalization, allocation and packing decisions, summary
  aggregation, provider counteroffers, and returned allocation projection
  remain with their existing owners.
- The facade passes its command-direction policy explicitly; no configuration
  is duplicated.
- Existing public report APIs and artifact row shapes remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Study.Manifest realized-activity input-schema extraction, selected in
`f3f73799` and implemented in `e6decc5e`.
`study/manifest.ex` moved from 4,008 to 3,836 lines; the dedicated owner is 181
lines.

Next candidate:
Implement and verify the selected ContactAllocation approval-policy ownership
extraction.

Blocked:
No.

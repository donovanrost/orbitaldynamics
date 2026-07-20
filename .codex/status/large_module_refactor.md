# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh source-report provenance fixture extraction.

Status:
Selected; implementation pending.

Selected boundary:
Move the accepted-state refresh request, result-set event scenario, and maneuver
feedback report builders out of the source-report input-provenance test module
into a named fixture owner. Keep the test's production calls, assertions, and
validation checks in the existing test module.

Selection evidence:
- The named production hotspots are already public facades: `CandidateRefresh`
  is 524 lines with no private functions, `CampaignPlanner` is 164 lines, and
  `OperatorReview` is 505 lines with no private functions.
- Their matching tests are split by responsibility, but
  `source_report_input_provenance_test.exs` remains a 1,473-line single-test
  module.
- Its three private builders occupy 197 lines and mix reusable scenario
  construction with the provenance assertions.
- Moving only those builders creates a smaller assertion-focused test without
  changing the production surface or dividing one end-to-end assertion flow.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. The same deterministic fixtures, production calls, assertions,
artifact validation, and async test behavior must remain unchanged.

Last completed slice:
Handoff property schema-provider extraction, selected in `70b42ade` and
implemented in `bbab975b`. The public `Schema` facade moved from 934 to 925
lines.

Next candidate:
Implement and verify the selected CandidateRefresh test-fixture extraction.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh source-report provenance fixture extraction.

Status:
Completed and verified.

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
Selected in `920500b6` and implemented in `c084366f`. Added the 200-line
`SourceReportInputProvenanceFixture` test-support owner and imported its three
public deterministic builders into the existing provenance test. The assertion
module moved from 1,473 to 1,277 lines.

Verification:
- The exact end-to-end source-report input-provenance test passed: 1 test.
- The full CandidateRefresh test lane passed with warnings as errors: 756 tests.
- Strict forced compile passed with warnings as errors: 4,129 files.
- `git diff --check` passed.
- No production or checked-in schema-export files changed.

Behavior/schema changes:
None intended. The same deterministic fixtures, production calls, assertions,
artifact validation, and async test behavior must remain unchanged.

Last completed slice:
Candidate-refresh source-report provenance fixture extraction, selected in
`920500b6` and implemented in `c084366f`. The assertion module moved from 1,473
to 1,277 lines.

Next candidate:
Continue the named-hotspot audit with the remaining oversized CampaignPlanner,
OperatorReview, and schema contract test units; select the next bounded split
only where a clear responsibility boundary exists.

Blocked:
No.

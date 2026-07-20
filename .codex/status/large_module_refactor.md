# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback operational-feedback aggregation extraction.

Status:
Completed and pushed in `8d9a5204`.

Selected boundary:
Extract operational-feedback dimension aggregation, outcome value selection,
weighted target-priority feedback, downlink/resource feedback delegation,
maneuver-execution-uncertainty projection, and provenance trust specs into
`OrbitalDynamics.TimelineFeedback.OperationalFeedbackSummary`.
Preserve all TimelineFeedback and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `timeline_feedback.ex` at 1,797 lines, the
  largest ordinary eligible facade.
- TimelineFeedback already delegates thirty focused responsibilities, while
  operational-feedback output construction and its value/trust helper family
  remain inline at lines 429-490 and 1,346-1,552.
- The selected block has one responsibility: aggregate reconciled rows into
  deterministic operational-feedback dimensions and matching trust specs.
- Planned/realized normalization, reconciliation rows, provenance construction,
  activity state, and all public contracts remain outside the boundary.
- Exact row normalization, exclusion handling, weighted averages, stable key
  routing, nested-map ordering, outcome/status interpretation, trust-spec
  callbacks, public output, and error behavior must remain unchanged.

Implementation:
- Added `OrbitalDynamics.TimelineFeedback.OperationalFeedbackSummary` as the
  owner of operational dimension aggregation, outcome value routing, weighted
  target priorities, delegated downlink/resource feedback, maneuver execution
  uncertainty projection, and provenance trust specs.
- Wired the existing operational-feedback and provenance paths directly to the
  owner while preserving TimelineFeedback and root public APIs.
- Kept row normalization/reconciliation, provenance construction, activity
  state, and exclusion counting in their existing owners.
- `timeline_feedback.ex` moved from 1,797 to 1,546 lines; the new owner is 252
  lines.

Verification:
- Strict focused baseline passed all 73 TimelineFeedback tests.
- Exact old/new public parity passed for four deterministic operational-feedback
  results: dense multi-dimension string-key rows, atom-key rows, report-map
  routing, and empty input.
- Post-extraction focused and adjacent TimelineFeedback, operator-review,
  strategy source-report, replay-summary, and schema-export verification passed
  all 91 tests.
- Static checks confirm the operational aggregation/trust helper family left
  the facade; xref reports only TimelineFeedback as a runtime caller.
- Strict warning-clean forced compile passed for 4,008 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
TimelineFeedback operational-feedback aggregation extraction, selected in
`da283212` and implemented in `8d9a5204`.
`timeline_feedback.ex` moved from 1,797 to 1,546 lines; the dedicated
OperationalFeedbackSummary owner is 252 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `resource_projection.ex` is now the largest ordinary eligible
facade at 1,789 lines, followed by ContactIntent and RecommendationRiskContext.

Blocked:
No.

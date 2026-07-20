# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback operational-feedback aggregation extraction.

Status:
Selected; strict focused baseline pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
ContactAllocation returned-allocation extraction, selected in `e7a28cf9` and
implemented in `cd708fc8`.
`contact_allocation.ex` moved from 1,804 to 1,707 lines; the dedicated
ReturnedAllocation owner is 110 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `timeline_feedback.ex` is now the largest ordinary eligible facade
at 1,797 lines, followed by ResourceProjection and ContactIntent.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback operational-feedback provenance extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract operational-feedback input-key detection, realized and weighted row
counts, weight-source and source-quality evidence, overall trust-boundary
aggregation, and per-feedback-key trust routing into
`OrbitalDynamics.TimelineFeedback.OperationalFeedbackProvenance`. Preserve all
TimelineFeedback and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `timeline_feedback.ex` at 1,948 lines, the largest
  ordinary eligible facade.
- TimelineFeedback already delegates to twenty-eight focused owners, while its
  operational-feedback provenance builder and helper family still occupy lines
  463-646.
- The selected block has one responsibility: explain which normalized report
  rows and trust boundaries produced each operational-feedback input.
- Feedback value derivation, reconciliation, realized normalization, activity
  state, resource/downlink/uncertainty aggregation, and all capability
  contracts remain outside the boundary.
- Exact input-key ordering, source counts, weighted-row semantics, source
  quality maps, trust-boundary routing, omission behavior, report provenance,
  reconciliation output, and error behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending strict focused baseline, exact old/new public parity, focused and
adjacent tests, static ownership checks, xref, strict warning-clean compile,
formatting, and diff checks.

Behavior/schema changes:
None intended.

Last completed slice:
ContactAllocation contact-validation extraction, selected in `325980b5` and
implemented in `6d894840`.
`communications/contact_allocation.ex` moved from 1,953 to 1,804 lines; the
dedicated ContactValidation owner is 205 lines.

Next candidate:
Complete the selected TimelineFeedback operational-feedback provenance
extraction.

Blocked:
No.

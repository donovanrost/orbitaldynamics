# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback operational-feedback provenance extraction.

Status:
Completed and pushed in `79d7904c`.

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
- Added `OrbitalDynamics.TimelineFeedback.OperationalFeedbackProvenance` as the
  owner of operational-feedback input keys, row/weight/source-quality counts,
  trust boundaries, and per-feedback-key trust routing.
- Preserved TimelineFeedback and root public APIs as reconciliation and
  operational-feedback delegates.
- Kept feedback-specific key/value functions in the facade and passed their
  trust-routing specifications into the generic provenance owner.
- `timeline_feedback.ex` moved from 1,948 to 1,797 lines; the new owner is 181
  lines.

Verification:
- Strict focused baseline passed all 73 TimelineFeedback tests.
- Exact old/new public parity passed for four deterministic report captures:
  omitted provenance, weighted multi-row contact feedback, source-quality and
  trust-boundary observation feedback, and excluded operational feedback.
- Post-extraction focused and adjacent verification passed all 76 tests.
- Static checks confirm the provenance aggregation helper family left the
  facade; xref reports only TimelineFeedback as a runtime caller.
- Strict warning-clean forced compile passed for 3,999 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
TimelineFeedback operational-feedback provenance extraction, selected in
`9782f23d` and implemented in `79d7904c`.
`timeline_feedback.ex` moved from 1,948 to 1,797 lines; the dedicated
OperationalFeedbackProvenance owner is 181 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `operational_readiness.ex` is now the largest ordinary eligible
facade at 1,927 lines, followed by StationCalendar and LinkCapacity.

Blocked:
No.

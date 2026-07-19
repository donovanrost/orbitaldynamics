# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness quality-gate import-readiness summary extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract quality-gate import-readiness row selection, count/status aggregation,
freshness/import-preparation/blocking predicates, routing IDs, publication
context projection, and summary construction into
`OrbitalDynamics.OperationalReadiness.QualityGateImportReadinessSummary`.
Preserve all OperationalReadiness and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `operational_readiness.ex` at 1,927 lines, the largest
  ordinary eligible facade.
- OperationalReadiness already delegates operator-training and
  schema-validation quality-gate summaries, while the import-readiness sibling
  builder remains at lines 775-873 and its specialized helpers at
  lines 1,067-1,120.
- The selected block has one responsibility: derive import readiness,
  freshness review, import preparation, and blocking routes from cadence-import
  quality-gate rows.
- Readiness report construction, gate classification, unavailable-resource and
  operator-training/schema summaries, evidence normalization, and all public
  contracts remain outside the boundary.
- Exact row selection, counts, status IDs, boolean decisions, publication
  context, omission behavior, summary fields, public facade output, and error
  behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending strict focused baseline, exact old/new public parity, focused and
adjacent tests, static ownership checks, xref, strict warning-clean compile,
formatting, and diff checks.

Behavior/schema changes:
None intended.

Last completed slice:
TimelineFeedback operational-feedback provenance extraction, selected in
`9782f23d` and implemented in `79d7904c`.
`timeline_feedback.ex` moved from 1,948 to 1,797 lines; the dedicated
OperationalFeedbackProvenance owner is 181 lines.

Next candidate:
Complete the selected OperationalReadiness quality-gate import-readiness
summary extraction.

Blocked:
No.

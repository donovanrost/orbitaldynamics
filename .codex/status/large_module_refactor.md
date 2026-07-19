# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback realized feedback validation extraction.

Status:
Completed and pushed.

Selected boundary:
Extract realized feedback unit-interval and nonnegative-weight path policy,
invalid-section construction, invalid value and orphaned source sanitization,
nested path lookup/deletion, valid/invalid factor and weight detection,
invalid-row annotation, and failure-reason classification into
`OrbitalDynamics.TimelineFeedback.RealizedFeedbackValidation`. Preserve all
public TimelineFeedback reconciliation, normalization, state, operational
feedback, and capability facades.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 2,267 lines, the largest
  eligible facade behind Schema, Timeline, MissionPlan.Activity, and the root
  public facade.
- The selected validation/sanitization family spans lines 1,095-1,374 and is
  reached through four private helpers during realized-input normalization and
  row construction.
- The family exclusively owns feedback-factor/quality/cloud/blur unit-interval
  policy, feedback-weight nonnegative policy, nested feedback paths, and
  invalid-section annotations.
- Reconciliation identity/matching, planned/realized row construction,
  operational feedback aggregation, throughput/resource/station/thermal/link
  contexts, publication, and artifact contracts remain outside this boundary.
- Existing path order, duplicate field reporting, number/string parsing,
  invalid number versus shape evidence, nested empty-map cleanup, fallback
  source preservation/removal, combined failure reason selection, exact keys,
  and deterministic section order must remain unchanged.

Implementation:
- Selection was recorded and pushed in `75aca312`.
- Implementation was committed and pushed in `60020f26`.
- `timeline_feedback.ex` moved from 2,267 to 1,993 lines.
- `OrbitalDynamics.TimelineFeedback.RealizedFeedbackValidation` is a 294-line
  owner reached through four private facade delegates.

Verification:
- Strict warning-clean compilation passed across 3,979 files.
- The focused TimelineFeedback file and five adjacent candidate-refresh,
  strategy, observation-feedback, provenance, and schema consumers passed
  together: 117 tests.
- Exact old/new public normalization/reconciliation parity passed for 16 cases
  covering valid and invalid contact/command/observation/maneuver factors,
  direct/nested fallback sources, quality/cloud/blur aliases, invalid numbers
  and shapes, weight aliases and sources, sanitization, row annotations, and
  capability metadata.
- `mix xref callers` reports only the TimelineFeedback facade.
- The facade-owned path policy, validation, sanitization, nested lookup/delete,
  source cleanup, and invalid-reason helpers are absent apart from four thin
  delegates, formatting and `git diff --check` passed, and the final diff is
  ownership-only.

Behavior/schema changes:
None intended.

Last completed slice:
TimelineFeedback realized feedback validation extraction, selected in
`75aca312` and implemented in `60020f26`.
`timeline_feedback.ex` moved from 2,267 to 1,993 lines; the dedicated realized
feedback validation owner is 294 lines.

Next candidate:
Re-rank the live checkout and select the next cohesive facade-preserving
boundary.

Blocked:
No.

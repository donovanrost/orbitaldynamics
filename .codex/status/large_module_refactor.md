# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback operational-feedback exclusion extraction.

Status:
Completed and pushed.

Selected boundary:
Extract operational-feedback exclusion reason/status assignment,
resource-availability variance detection, feedback-kind identity rules,
invalid feedback-weight detection, contact link-quality review detection, and
status normalization into
`OrbitalDynamics.TimelineFeedback.OperationalFeedbackExclusion`. Preserve the
public TimelineFeedback facade through the reconciliation-row private delegate.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 2,608 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity, and one line ahead of
  RecommendationRiskContext.
- The selected family spans lines 1,766-1,903. It owns all
  operational-feedback exclusion reasons, their review-only statuses,
  resource-state mismatch fields, observation/contact identity rules, invalid
  weight aliases, link lock/margin/status rules, and status token
  normalization.
- Only reconciliation-row construction consumes this responsibility through
  `put_operational_feedback_exclusion/1`.
- Reconciliation evidence construction, duplicate realized feedback,
  aggregation, demand/resource/priority feedback, public clauses, and artifact
  contracts remain outside this boundary.
- Existing reason precedence, status mapping, exact mismatch fields, contact
  kinds, invalid-weight aliases, failure-status vocabulary, negative-margin
  semantics, token normalization, no-exclusion pass-through, and deterministic
  output must remain unchanged.

Implementation:
- Selection was recorded and pushed in `cb84add9`.
- Implementation was committed and pushed in `9ce4d7bb`.
- `timeline_feedback.ex` moved from 2,608 to 2,472 lines.
- `OrbitalDynamics.TimelineFeedback.OperationalFeedbackExclusion` is a
  142-line owner reached through the original private facade delegate.

Verification:
- Strict warning-clean compilation passed across 3,958 files.
- The focused TimelineFeedback file and four adjacent operational-feedback
  consumers passed together: 89 tests.
- Exact old/new row parity passed for 12 cases covering no-op rows,
  observation target and pointing mismatches, contact identity mismatches,
  link-lock, negative-margin and normalized failure-status review, resource
  variance, invalid weight aliases, and precedence.
- `mix xref callers` reports only the TimelineFeedback facade; the
  compile-connected graph reports the new owner and facade.
- The removed private helper family is absent from the facade, formatting and
  `git diff --check` passed, and the final diff is ownership-only.

Behavior/schema changes:
None intended.

Last completed slice:
TimelineFeedback operational-feedback exclusion extraction, selected in
`cb84add9` and implemented in `9ce4d7bb`. `timeline_feedback.ex` moved from
2,608 to 2,472 lines; the dedicated exclusion owner is 142 lines.

Next candidate:
Re-rank the live checkout and select the next cohesive facade-preserving
boundary.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback operational-feedback exclusion extraction.

Status:
Selected; implementation not started.

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

Verification plan:
- Run the strict warning-clean compile before and after implementation.
- Run the focused TimelineFeedback regression file and adjacent operational
  feedback/reconciliation consumers selected from live references.
- Run exact old/new parity from this selection commit across invalid weights,
  resource variance, observation/contact identity mismatches, link locks,
  margins and status aliases, precedence, no-exclusion rows, deterministic
  reports, and public errors.
- Run `mix xref callers` for the new owner, inspect compile-connected
  dependents, check formatting and `git diff --check`, prove the removed
  helper family is absent from the facade, and review final facade/owner
  boundaries.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext contact-intent extraction, selected in `3ba6891a`,
implemented in `f7b9a0d0`, and handed off in `5b2c0104`.
`recommendation_risk_context.ex` moved from 2,748 to 2,607 lines; the dedicated
contact-intent owner is 178 lines.

Next candidate:
Implement and verify the selected TimelineFeedback operational-feedback
exclusion extraction.

Blocked:
No.

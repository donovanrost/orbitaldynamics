# 13. V2 Rolling Repair

Status: **implemented** (with **partial**, **near-term**, **later**, and **out of scope** items noted below).

## Repair entry point and inputs

- **Entry point** — `CampaignPlanner.repair/1`.
- **Inputs** — the prior plan plus realized state.
- **Optional candidate replacement** — `candidate_refresh.v1` candidate replacement.

## Realized-activity handling

- Handles missed, failed, delayed, canceled/cancelled, rejected, partial, completed, and executed activities.
- Produces preserved activities, plan deltas, churn costs, and degraded payload suppression.
- Produces approval requirements with `policy_decision.v1` approval classification.
- Carries candidate-source provenance.
- Carries operational activity context in deltas, replacement metadata, and approval requirements.
- Carries source/replacement `timeline_identity` metadata for moved or replaced activities.

## Reports emitted over repaired activities

- **`operational_timeline_report.v1`** rows over the repaired activity list.
- **`timeline_transition_application_report.v1`** rows over the source and repaired activity lists, including:
  - selected safe activities;
  - review-required transition applications;
  - repair metadata counts for selected/review-gated application rows;
  - embedded operator-review plus Cadence-import rows for those review-gated transition applications, including approval-policy rule-match and policy-decision evidence when repair policy rules match transition/application/protection context.

## Timeline protection

- `repair_metadata.timeline_protection` counts and lists preserved or changed locked/approved/executed activities.
- Locked or approved activities are preserved before degraded-mode payload suppression when they are not already realized as missed, failed, delayed, or terminal.
- Partial, completed, or executed preserved-executed activities carry realized timing and `completed_fraction` evidence in their repair metadata when supplied.
  - Their plan deltas, review rows, and Cadence import rows preserve the `preserved_executed` action instead of flattening them to generic preserved items.

## Duplicate realized rows

- Duplicate realized activity rows for the same planned activity no longer collapse to one status during repair.
- Instead, repair preserves the planned activity with:
  - `review_realized_feedback` repair metadata;
  - plan-delta evidence;
  - a `realized_feedback_review` approval requirement;
  - an operator-review warning.

## Constraint reports

- V2 repair artifacts emit `constraint_report.v1` rows over inherited planner-local constraints:
  - max-timeline-activity;
  - minimum-duration;
  - eclipse-avoidance;
  - resource projection and link-capacity constraints.
- These are evaluated against the repaired activity set and source resource summaries, preserving explicit warning severity in repair and branch-comparison rows.

## Repair score terms

- V2 computes `link_capacity_report.v1` before repair scoring so selected repaired
  downlink capacity participates in the same decision artifact it explains.
- A positive `selected_downlink_shortfall_mb` contributes one normalized
  `risk_weight` unit through `link_capacity_pressure_penalty`; satisfied or
  undeclared demand does not emit that conditional term.
- Repair-time station-calendar rows contribute one normalized `risk_weight`
  unit through `station_calendar_pressure_penalty` only when the affected
  contact ID is present in the repaired selected activities and the shared V3
  calendar-pressure classifier identifies reserved, unavailable, or reduced
  capacity pressure. Affected but unselected alternatives do not change score.
  Replacement ranking uses the same classifier and subtracts the same calibrated
  unit from pressure-bearing candidates within each semantic candidate-diff
  priority tier. This can prefer a slightly lower-value nominal contact while a
  smaller weight can still select the pressured alternative; calendars remain
  annotation/review evidence rather than hard candidate suppression.
- `resource_projection_pressure_penalty` counts every risk emitted by
  `ResourceProjectionRisk.risk_indicators/1`, including storage/downlink/battery,
  negative thermal margin, spacecraft or payload/antenna availability, degraded
  payload, and selected activity compatibility pressure. Nominal projections
  still omit the conditional term.
- A candidate-refresh `freshness_report.v1` with normalized `stale` or `unknown`
  status contributes exactly one source-wide normalized `risk_weight` unit
  through `refresh_freshness_pressure_penalty`. Current or absent reports omit
  the conditional term while stale/unknown review and import gates remain
  preserved.
- A candidate-refresh `candidate_diff_report.v1` contributes exactly one
  source-wide normalized `risk_weight` unit through
  `candidate_diff_pressure_penalty` when the shared V3 replay classifier finds
  new, invalidated, semantic-change, candidate-routing, or station-routing
  pressure. Multiple rows remain one aggregate unit; empty or absent reports
  omit the term.
- The repair score, `score_terms`, and `score_term_report.v1` preserve the same
  total and expose the selected communications gap without claiming a link
  budget, provider reservation, or schedule mutation.

## Refreshed missed-contact repair

- Treats the following as movable contact windows after canonical downlink/station/time normalization:
  - native downlink rows;
  - `planned_contact` rows whose direction is `downlink`;
  - provider-shaped prior-plan station/time rows that omit explicit type or direction, including nested `station` / `ground_station` identity objects.
- Command/uplink planned contacts remain outside the downlink repair path.
- Refreshes contact intents, contact allocation reports, and resource summaries when supplied by `candidate_refresh.v1`.

## Candidate-diff replacement selection

- Semantic candidate-diff replacement links from supplied `candidate_refresh.v1` artifacts are used to prefer matching refreshed replacement candidates and are preserved in moved/replaced activity repair metadata.
- Duplicate replacement candidate IDs are excluded from automatic move/replacement selection, so repair does not choose between ambiguous candidate rows by sort order.
- Mission-state and supplied-refresh `candidate_rejection_report.v1` evidence is consulted during automatic replacement selection, so rejected replacement candidates are excluded even when they have higher scores. Repair artifacts preserve the source candidate-rejection report and lift it into operator-review and Cadence-import handoff rows for audit.

## Additional reports and reconciliation

- Thin V2 resource projection reports over repaired activities and source resource summaries.
- Source timeline-feedback reconciliation over planned-vs-realized activities when realized activities are supplied.
- Repaired-activity contact allocation reports over the repaired contact set.

## Executable refresh requests

- Repair-level executable `candidate_refresh_request` support when a prebuilt refresh artifact is not supplied, including preservation of explicit repair approval policy into generated refresh contact intents and nested review evidence.
- Generated and supplied refresh warnings — including resource-filter suppression warnings and invalid source contact-filter input warnings — are preserved on the V2 repair artifact alongside source resource-filter and contact-filter report provenance, so operator-review and Cadence-import queues can see refresh-time suppression evidence.

## Station-calendar and examples

- Repair-time station-calendar annotation with `source_station_calendar_report`.
- Repaired JSON artifact examples.

## Operator-review package (`operator_review_package.v1`)

Status: **implemented**.

V2 repair `operator_review_package.v1` now emits:

- **Plan-delta review rows** for repaired timeline changes and preservation decisions, including:
  - explicit timeline-protection rows for locked, approved, or executed activities preserved or changed by repair;
  - source and replacement timeline identity/context fields on plan-delta review rows;
  - flattened source/replacement Cadence import status, import type, external ID, schema contract, and presence flags alongside invalid non-object source/replacement Cadence import evidence when repair activity contexts are malformed, while sanitizing the nested contexts before operator-review and Cadence-import validation.
- Approval requirements.
- Repair score-term and objective-tradeoff review rows.
- Repaired-plan link-capacity review rows.
- Repaired-plan and source contact-allocation review rows.
- Source candidate-diff rows.
- Source contact/resource-suppression rows.
- Source refresh-freshness and refresh-budget review rows.
- Source resource-projection review rows.
- Warnings.

## Cadence import manifest (`cadence_import_manifest.v1`)

- V2 repair artifacts now include `cadence_import_manifest.v1` rows that convert the full repair operator-review package — including contact-allocation, link-capacity, refresh-budget, and resource-projection review rows plus typed policy-escalation authority queues — into deterministic, review-gated import actions for downstream Cadence schedule/import adapters without executing those imports.
- V3 strategy artifacts emit the same manifest contract over branch-comparison rows with selected-branch recommendation import actions and non-selected branch alternative-review rows.
- Checked-in V2 repair and V3 strategy JSON requests can be executed through public file-backed helpers that resolve `source_plan_ref` into the prior plan artifact before planning.
- V1 campaign import manifests now include station-contention recommendation review rows, and standalone contact-contention group/resolution reports can be converted into review-gated import manifests.

## Partial

Status: **partial**.

Repair consumes refreshed candidate sets, contact intents, resource summaries, refresh budget reports, and contact-allocation reports when supplied or generated from a repair refresh request, and can annotate repair source contacts from station-calendar updates. However, it:

- still has thin degraded-mode semantics;
- has no reservation/schedule-mutation model;
- has no calibrated subsystem resource simulation.

## Near-term

Status: **near-term**.

Deepen calibrated behavior behind the artifact-only review/import queues. Adapter-facing row status and deterministic source-queue summaries are now present.

## Later

Status: **later**.

Rolling-horizon service boundary, resource-aware repair, uncertainty margins, and plan-delta APIs designed for operator review.

## Out of scope

Status: **out of scope**.

Cadence realized-state database ownership or automatic operational schedule mutation.

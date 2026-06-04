# Branch Timeline-Diff Replay and Other Report Fields

## Timeline-diff replay into branch-local refresh events

Prior `source_timeline_diff_report` or `timeline_diff_report` rows, plus `timeline_diff_report.v1` rows embedded in prior `source_result_artifact` / `result_artifact` wrappers, feed branch-local refresh derivation.

Before becoming target-revisit refresh events, they normalize removed-observation:

- diff status
- activity type
- direction
- source status
- changed-field case/whitespace/hyphen variants

### Removed-row mapping (missed-work semantics)

Removed rows map to refresh events by type:

- **Removed downlink rows** become downlink-completion-gap refresh events.
- **Removed tracking or tracking-direction planned-contact rows** become contact-success-feedback events.
- **Removed command, uplink, or health-check contact rows** become command-success-feedback events.
- **Removed maneuver or impulsive-burn rows** become maneuver-success-feedback events with missed-work semantics.

Each preserves: timeline ID, source activity, required operator action, removed contact/timing evidence, contact-count evidence, source context, and report or wrapper trust-boundary evidence.

### Wrapper keys and duplicate identities

- **Wrapper keys** — Prior result-artifact wrappers may use either the canonical `timeline_diff_report` key or the adapter-facing `source_timeline_diff_report` key; both replay through the same branch-local derivation with distinct source-path provenance.
- **Duplicate timeline-diff pressure identities** — Retained as independent branch events with deterministic suffixes from report source, timeline/activity identity, changed fields, status-transition category/review metadata, routing, required work, timing, application context, and trust-boundary evidence.

### Transition application rows

Timeline transition application rows that carry duplicate timeline-identity collision evidence also feed `candidate_refresh.v1` source-report duplicate counts and V3 branch event fields from their top-level application rows. Branch-local replay therefore does not have to reopen nested `source_timeline_diff` rows to route duplicate-identity review pressure.

Operator-review packages and Cadence import manifests that carry `source_timeline_application` or `source_timeline_transition_application` rows now replay those same transition applications into branch-local timeline-diff feedback, with source paths naming the reviewed/imported application handoff.

## Changed-row mapping by activity type

### Downlink rows

**Downlink-completion-gap** — Changed timeline-diff downlink rows with explicit downlink-completion shortfall or required-vs-planned volume evidence — including nested provider data-volume requirement, selected/planned volume, and shortfall aliases — become downlink-completion-gap refresh events. They preserve:

- source/replacement activity IDs
- schema-safe changed fields with sparse provider nil entries removed
- volume evidence
- exact downlink-demand/completion source lineage from row or nested source/replacement activity contexts
- trust-boundary context

### Contact rows

**Contact-success-feedback** — Changed timeline-diff contact rows, including native `tracking` activity diffs, with failed contact-result, success-factor, replacement-status, or typed status-transition evidence become contact-success-feedback branch events. They preserve: source/replacement activity IDs, timing, changed fields, station routing, provider contact-result and realized-status evidence, feedback key, status-transition category/review metadata, and trust-boundary context.

### Downlink/contact station throughput

**Station-throughput-feedback** — Changed timeline-diff downlink/contact rows with explicit station-throughput factor below the branch policy threshold or degraded actual-vs-expected throughput evidence become branch-local station-throughput-feedback events. Healthy throughput rows remain report evidence only. Preserves: actual/estimated throughput, station routing, source/replacement activity IDs, timing, changed fields, feedback key, and trust-boundary context.

### Downlink/contact link quality

**Contact-success-feedback (link quality)** — Changed timeline-diff downlink/contact rows with explicit failed link-quality evidence — including lost carrier/symbol lock, negative link margin, low-margin/degraded/failure status aliases, or planned-vs-realized RF profile mismatches across protocol, band, modulation, coding, polarization, or declared data rate — now become branch-local contact-success-feedback events. Nominal link-quality rows with matching RF profiles remain report evidence only. Preserves: RF quality metrics, lock status, link-profile mismatch fields, station routing, source/replacement activity IDs, timing, changed fields, feedback key, and trust-boundary context.

### Downlink/contact routing identity

**Contact-success-feedback (routing identity)** — Changed timeline-diff downlink/contact rows with planned-vs-realized routing identity mismatches across direction, ground station, or source window become branch-local contact-success-feedback events. Matching completed routing rows remain report evidence only. Preserves: planned/realized routing fields, mismatch reasons, source/replacement activity IDs, timing, changed fields, feedback key, and trust-boundary context.

### Collection latency

**`downlink_completion_gap` scoped as `collection_latency`** — Changed timeline-diff rows with explicit collection-latency gap, late status, or planned-vs-limit latency violation become branch-local `downlink_completion_gap` events scoped as `collection_latency`. On-time latency rows remain report evidence only. Preserves: objective, target, station, collection/product/payload/instrument, source/replacement activity, latency, changed-field, and trust-boundary context.

## Observation rows

### Observation result

**Target-revisit refresh** — Changed timeline-diff observation rows with failed observation-result, success-factor, replacement-status, or typed status-transition evidence become target-revisit refresh events. Preserves: source/replacement activity IDs, timing, changed fields, provider observation-result and realized-status evidence, feedback key, staged feasibility provenance, status-transition category/review metadata, and trust-boundary context.

### Observation quality

**Observation-quality feedback** — Changed observation timeline-diff rows with replacement or source image-quality score, image-quality status/source, cloud-cover fraction, or blur score also replay as branch-local observation-quality feedback and into CandidateRefresh operational-feedback maps. This allows degraded imagery evidence to affect refreshed observation scoring without pre-flattened realized feedback.

### Observation target identity

**Observation-success feedback (target identity)** — Changed observation timeline-diff rows with explicit planned-vs-realized target identity mismatch replay as branch-local observation-success feedback for the planned target. Matching target-identity rows remain report evidence only. Preserves: planned/realized target IDs, result/status evidence, source/replacement activity, changed-field, and trust-boundary context.

### Observation product identity

**Observation-success feedback (product identity)** — Changed observation timeline-diff rows with explicit planned-vs-realized collection, product, product selector set, payload, or instrument identity mismatch also replay as branch-local observation-success feedback for the planned target. Matching product identity rows remain report evidence only. Preserves: planned/realized collection/product/product-set/payload/instrument IDs, mismatch reasons, result/status evidence, source/replacement activity, changed-field, and trust-boundary context.

### Observation pointing/attitude

**Observation-success feedback (pointing/attitude)** — Changed observation timeline-diff rows with explicit pointing/attitude target or mode mismatch, failed pointing/attitude status, or degraded pointing/attitude status now replay as branch-local observation-success feedback. Nominal pointing rows remain report evidence only. Preserves: planned/realized pointing and attitude identity, status, error, model/source, source/replacement activity, changed-field, and trust-boundary context.

### Observation lighting/eclipse

**Observation-success feedback (lighting/eclipse)** — Changed observation timeline-diff rows with explicit realized eclipse overlap or degraded/eclipsed lighting condition/detail evidence now replay as branch-local observation-success feedback. Nominal sunlit rows remain report evidence only. Preserves: planned/realized lighting condition, lighting detail/model/confidence, eclipse-overlap fraction/duration, source/replacement activity, changed-field, and trust-boundary context.

### Observation target priority

**`target_priority_feedback`** — Changed observation timeline-diff rows with replacement, source, or top-level target priority at or above the branch policy threshold replay as branch-local `target_priority_feedback`. Low-priority target changes remain report evidence only. Preserves: target geometry, objective metadata, source activity, timeline ID, changed fields, and trust-boundary context.

## Command rows

### Command result

**Command-success-feedback** — Changed timeline-diff command rows, including provider-shaped `planned_contact` or `contact` rows with command, uplink, or health-check direction, with failed command-result, success-factor, replacement-status, or typed status-transition evidence become command-success-feedback branch events. Preserves: source/replacement activity IDs, timing, changed fields, provider command-result and realized-status evidence, status-transition category/review metadata, and trust-boundary context.

### Command routing identity

**`command_success_feedback`** — Changed command timeline-diff rows with explicit planned-vs-realized direction, ground-station, or source-window mismatch also become branch-local `command_success_feedback` events. Matching successful command rows remain report evidence only. Preserves: command routing identity, source/replacement activity IDs, timing, changed fields, result/status evidence, and trust-boundary context.

## Resource margin and availability

### Margin pressure

**`resource_margin_pressure`** — Changed timeline-diff rows with replacement, source, or top-level low fuel, power, storage, downlink, or thermal margin evidence at or below the row/policy threshold become branch-local `resource_margin_pressure` events.

Thermal margin can also be deterministically derived from externally supplied measured/actual temperature and declared operating-temperature bounds, without adding thermal propagation or subsystem simulation. Healthy changed margins remain report evidence only.

### Availability constraints

- **`resource_availability_constraint`** — Payload, antenna, or spacecraft availability evidence set false becomes branch-local `resource_availability_constraint` events.
- **Planned-vs-realized resource identity mismatches** — Also replay as branch-local resource-availability constraints for the planned activity's resource class:
  - observation resources map to payload availability
  - contact/command resources map to antenna availability
  - maneuver resources map to spacecraft availability

These preserve: planned/realized resource IDs, mismatch status, source/replacement activity IDs, timing, changed fields, temperature/bound/status/model/source context for thermal rows, degraded/mode context, resource-filter suppression behavior, and trust-boundary context.

## Maneuver rows

**Maneuver-success-feedback** — Changed timeline-diff maneuver rows, including typed `impulsive_burn` activity diffs, with failed maneuver-result, success-factor, replacement-status, or typed status-transition evidence become maneuver-success-feedback branch events.

**Maneuver-execution-uncertainty feedback** — Rows with replacement/source maneuver execution-uncertainty maps or missing uncertainty status become maneuver-execution-uncertainty feedback events.

Both preserve: source/replacement activity IDs, timing, changed fields, provider maneuver-result, realized-status, covariance/source evidence, status-transition category/review metadata, maneuver-key-scoped operational feedback, provenance counts, and trust-boundary context.

## Transition application reports

Prior `source_timeline_transition_application_report` or `timeline_transition_application_report` applications, plus `timeline_transition_application_report.v1` applications embedded in prior `source_result_artifact` / `result_artifact` wrappers — including the adapter-facing `source_timeline_transition_application_report` wrapper key — feed the same timeline-diff branch-local refresh derivation. They preserve `application_status`, selected-activity context, source application evidence, and report or wrapper trust-boundary provenance.

Operator-review and Cadence-import rows may preserve either `source_timeline_application` or the explicit `source_timeline_transition_application` alias; both replay into the same timeline-diff branch path with distinct source-path provenance. They also contribute synthesized `timeline_transition_application_report.v1` summaries under `candidate_refresh.v1` source-report provenance, including duplicate timeline-identity collision counts and scope counts.

## Cadence import manifests

Prior `cadence_import_manifest.v1` rows that preserve source review rows can also feed the same branch-local refresh derivation as operator-review packages. This includes:

- timeline-diff, including nested or flattened timeline-diff rows
- timeline-transition-application
- score-term
- objective
- constraint
- resource, including nested or flattened resource-projection rows
- link-capacity, including nested or flattened link-capacity rows
- contact-contention recommendation
- contact-allocation, including nested or flattened contact-allocation rows
- realized-feedback pressure rows

Realized-feedback import rows that carry review fields at the top level are reconstructed into the same review-shaped feedback input, without requiring the original review package or source report to be resubmitted.

### Top-level Cadence import rows

Top-level Cadence import rows that preserve `source_objective_satisfaction`, `source_objective_tradeoff`, `source_score_term`, or `source_constraint_row`, plus:

- flattened timeline-diff rows
- resource-projection, including flattened resource-projection rows
- link-capacity, including flattened link-capacity rows
- contact-allocation, including flattened contact-allocation rows
- contact/resource suppression, including flattened suppression rows
- contact-contention `source_recommendation` or flattened recommendation rows
- flattened objective-satisfaction or objective-tradeoff rows
- flattened score-term or constraint rows
- contact-suppression, or resource-suppression source rows

likewise feed branch-local objective, tradeoff, score-term, constraint, communications, and resource refresh derivation without a nested review row. Inert nested `source_review_row` wrappers do not hide those top-level replay fields.

## Strategy recommendation and operational-feedback replay

- **Strategy recommendation import rows** that preserve `source_operational_feedback` can seed later V3 strategy feedback merges and branch-local feedback derivation without reopening the original strategy artifact.
- **Operator-review strategy recommendation rows** with the same `source_operational_feedback` fields are accepted by that replay path as well, inheriting package-level trust boundaries when row-level trust is absent.
- **Cadence import rows** whose nested `source_review_row` preserves `source_operational_feedback` replay through the same source path when the top-level import row does not already carry it, with manifest-level trust boundaries used when row-level trust is absent.

When these replay rows come from single or list-valued review/import artifacts, the stable aggregate provenance source label is retained while `source_report_paths` identifies the contributing package row or nested Cadence import source-review row.

### Trust boundaries and invalid feedback

- Candidate-refresh warning rows and their Cadence import handoffs likewise preserve invalid `source_operational_feedback` maps for review-only replay evidence.
- Direct report-level or nested `source_operational_feedback_provenance` trust-boundary evidence, including field-specific `feedback_trust_boundaries`, is lifted into the replay source metadata and derived branch-event trust routing.
- Malformed replayed `source_operational_feedback` rows are retained as invalid provenance evidence without contributing branch-scoring feedback.

## Operator-review package replay

Prior `operator_review_package.v1` rows that preserve source objective-satisfaction, objective-tradeoff, constraint (including nested or flattened constraint rows), timeline-diff, timeline-transition-application, nested or flattened resource-projection rows, nested or flattened link-capacity rows, nested or flattened contact-contention recommendation, nested or flattened objective-satisfaction/objective-tradeoff rows, nested or flattened score-term rows, or nested or flattened contact-allocation rows feed the same branch-local refresh derivation without requiring the original source report to be resubmitted.

## Repair and capacity rationale

- **Strategic additions** preserve repair reasons specific to their objective or pressure source rather than only a generic inserted-candidate label.
- **Downlink completion gap risks** preserve contact-count versus MB-volume rationale for recommendation review.
- **Candidate-plan capacity adjustments** export their own reduced-capacity row shape, including unit-interval `capacity_fraction`, instead of reusing raw strategy event feedback fields.

## Report fields

- **`branch_comparison_report`** with raw score, branch probability, expected score, risk type and high-risk type summaries, flattened resource margins, availability, resource score adjustment, fuel-preservation mode, feedback score adjustment, contact/observation/maneuver/command/station-throughput feedback factors, feedback risk types, resource risk types, reduced-capacity contact-allocation pack summaries, repaired score/link-capacity summaries, and repaired constraint counts/statuses.
- **`score_term_report`** with branch-level score-term rows keyed by branch ID, preserving the strategy scoring vocabulary in the same reusable `score_term_report.v1` shape used by V1/V2.
- **`objective_tradeoff_report`** with branch-level score deltas from the recommended branch, keyed by branch ID and preserving the same score-term map.
- **`ranking_comparison_report`** comparing normalized branch order with score-ranked branches for persisted rank-delta review.
- **`pareto_frontier_report`** summarizing branch objective-vector dominance over the generated branch set, including repaired constraint warning/fail counts as minimization objectives, for persisted frontier/dominated review.
- **`recommendation`** with ranked branch IDs, approval status, tradeoffs, and operator-facing explanations.
- **`operator_review_package`** with recommendation, tradeoff, approval, risk, score-term, objective-tradeoff, ranking-comparison, Pareto-frontier, branch repair constraint, operational-timeline, contact-suppression, contact-allocation, resource-suppression, branch resource-projection, and warning rows for artifact-only operator import/review workflows.

## Ground-station outage, reservation, and reduced-capacity events

Branch ground-station outage/reservation and reduced-capacity events apply to the same contact-direction boundary as communications reports:

- Native `downlink` rows and direction-`downlink` `planned_contact` rows are affected for downlink capacity.
- Outage/reservation events also affect typed tracking and health-check station activities.
- Command/uplink planned contacts are **not** treated as downlink capacity.

Synthesized missed feedback from outage/reservation branch events preserves ground-station and reservation context, so downstream timeline feedback, operator-review, and import rows can explain the station cause without reopening branch event internals.

Reduced-capacity branch events populate the station-capacity fields consumed by link-capacity and resource-projection reports, so branch repair artifacts expose capacity-adjusted throughput rather than only a lower candidate score.

- **`cadence_import_manifest`** with deterministic recommendation import rows for the selected branch, review rows for branch alternatives, and generic review-gated rows from the strategy operator-review package. If the source V3 artifact omits an embedded `operator_review_package`, the import manifest derives one and marks provenance with `operator_review_package_source: derived` plus the derived `source_review_count`.

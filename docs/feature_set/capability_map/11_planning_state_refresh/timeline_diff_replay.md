# Timeline-Diff and Transition-Application Replay

## Constraint-report replay (resource margins and downlink shortfalls)

Prior `source_constraint_report` or `constraint_report` rows are replayed, plus `constraint_report.v1` rows embedded in prior `source_result_artifact` / `result_artifact` wrappers, and constraint rows preserved in operator-review packages or Cadence-import manifests.

**Resource-margin normalization and refresh derivation:**

- Failed or warning resource-margin constraints normalize status, severity, and metric case/whitespace/hyphen variants before deriving branch-local `resource_margin_pressure` refreshes.
- Refreshes are derived only when the constraint carries a numeric margin value.
- Derivation preserves constraint ID, metric, value, threshold, severity, source activity, and report or wrapper trust-boundary evidence.
- This includes campaign constraint-key metrics such as `min_projected_*_margin`, including fuel and `thermal_margin_c`.

**Downlink-completion gap derivation:**

- Failed or warning selected-downlink-shortfall or provider data-volume-shortfall constraints can derive `downlink_completion_gap` refreshes from `value` or row-local shortfall fields such as `selected_downlink_shortfall_mb`.
- This is derived only when explicit station routing is present.
- Routing evidence is accepted from nested `ground_station` / `station` objects and from nested selected/source/contact station objects.
- It preserves required/planned downlink volume and shortfall evidence — including provider data-volume aliases — from top-level fields, nested `throughput_model` / `activity_context`, or nested selected/source/contact objects.
- It also preserves nested contact scenario, time-window, and contact-count evidence; exact downlink-demand/completion source lineage; time windows; contact-count evidence; source contacts from flattened IDs or nested contact objects; and trust-boundary context.

**Duplicate-identity handling:**

- Duplicate constraint identities from source and canonical reports are retained as independent pressure branches.
- Suffixes are derived from report source, constraint metric/type, spacecraft/resource identity, source activity, routed downlink evidence, timing, and trust-boundary context.
- Non-duplicated constraints keep their historical unsuffixed IDs.

**Nested / flattened replay:** Nested or flattened operator-review and Cadence-import constraint rows replay the same resource-margin and routed downlink-shortfall pressure without reopening the source constraint report.

## Timeline-diff replay (removed rows)

Prior `source_timeline_diff_report` or `timeline_diff_report` rows are replayed, plus `timeline_diff_report.v1` rows embedded in prior `source_result_artifact` / `result_artifact` wrappers. These normalize removed-observation diff status, activity type, direction, source status, and changed-field case/whitespace/hyphen variants before deriving target-revisit refreshes.

**Removed-row derivations (missed-work semantics):**

- Removed downlink rows can derive downlink-completion refreshes.
- Removed `tracking` or tracking-direction planned-contact rows derive contact-success feedback.
- Removed command, uplink, or health-check contact rows derive command-success feedback.
- Removed maneuver or impulsive-burn rows derive maneuver-success feedback.

All of the above preserve timeline ID, source activity, required operator action, removed contact/timing evidence, contact-count evidence, source context, and report or wrapper trust-boundary evidence.

**Duplicate-identity handling:**

- Duplicate timeline-diff pressure identities from source/canonical diff or transition-application reports are retained as independent pressure branches.
- Suffixes are derived from report source, timeline identity, source/replacement activity identity, changed fields, status-transition category/review metadata, station/target routing, required work, timing, application context, and trust-boundary evidence.
- Non-duplicated diffs keep their historical unsuffixed IDs.

**Transition-application collision replay:** Transition-application duplicate timeline-identity collision fields now also replay from top-level application rows into `candidate_refresh.v1` source-report duplicate counts and V3 branch events. This lets branch-local refresh route duplicate-identity review pressure without reopening nested `source_timeline_diff` evidence.

**Operator-review and Cadence-import applications:** Operator-review packages and Cadence import manifests that preserve `source_timeline_application` or `source_timeline_transition_application` rows now replay those transition applications into candidate-refresh timeline-diff feedback with reviewed or imported application source-path provenance.

## Changed-row derivations

### Downlink rows

- Changed timeline-diff downlink rows with explicit downlink-completion shortfall or required-vs-planned volume evidence — including nested provider data-volume requirement, selected/planned volume, and shortfall aliases — can derive downlink-completion refreshes.
- These preserve source/replacement activity IDs, schema-safe changed fields with sparse provider nil entries removed, volume evidence, exact downlink-demand/completion source lineage from row or nested source/replacement activity contexts, and trust-boundary context.
- The same typed activity provider data-volume evidence now has executable coverage through timeline diff, operator-review, Cadence-import, and V3 replay handoffs. Timeline-diff timing remains feedback evidence instead of constraining the recovery-candidate search window.

### Contact rows

- Changed timeline-diff contact rows — including native `tracking` activity diffs — with failed contact-result, success-factor, replacement-status, or typed status-transition evidence can derive contact-success feedback branches.
- These preserve source/replacement activity IDs, timing, changed fields, station routing, provider contact-result and realized-status evidence, feedback key, status-transition category/review metadata, and trust-boundary context.

### Station throughput

- Changed timeline-diff downlink/contact rows with explicit station-throughput factor below the branch policy threshold or degraded actual-vs-expected throughput evidence now derive branch-local `station_throughput_feedback`.
- Healthy throughput rows remain report evidence only.
- These preserve actual/estimated throughput, station routing, source/replacement activity IDs, timing, changed fields, feedback key, and trust-boundary context.

### Link quality

- Changed timeline-diff downlink/contact rows with explicit failed link-quality evidence — including lost carrier/symbol lock, negative link margin, low-margin/degraded/failure status aliases, or planned-vs-realized RF profile mismatches across protocol, band, modulation, coding, polarization, or declared data rate — now derive branch-local `contact_success_feedback`.
- Nominal link-quality rows with matching RF profiles remain report evidence only.
- These preserve RF quality metrics, lock status, link-profile mismatch fields, station routing, source/replacement activity IDs, timing, changed fields, feedback key, and trust-boundary context.

### Routing identity (contacts)

- Changed timeline-diff downlink/contact rows with planned-vs-realized routing identity mismatches across direction, ground station, or source window now derive branch-local `contact_success_feedback`.
- Matching completed routing rows remain report evidence only.
- These preserve planned/realized routing fields, mismatch reasons, source/replacement activity IDs, timing, changed fields, feedback key, and trust-boundary context.

### Collection latency

- Changed timeline-diff rows with explicit collection-latency gap, late status, or planned-vs-limit latency violation now derive branch-local `downlink_completion_gap` events scoped as `collection_latency`.
- On-time latency rows remain report evidence only.
- These preserve objective, target, station, collection/product/payload/instrument, source/replacement activity, latency, changed-field, and trust-boundary context.

### Observation rows (target revisit)

- Changed timeline-diff observation rows with failed observation-result, success-factor, replacement-status, or typed status-transition evidence can derive target-revisit refreshes.
- These preserve source/replacement activity IDs, timing, changed fields, provider observation-result and realized-status evidence, feedback key, staged feasibility provenance, status-transition category/review metadata, and trust-boundary context.

### Observation quality

- Changed observation timeline-diff rows that carry replacement or source image-quality score, image-quality status/source, cloud-cover fraction, or blur score now also derive branch-local observation-quality feedback events and `candidate_refresh.v1` operational-feedback maps.
- This lets degraded imagery evidence affect refreshed observation scoring from V3 timeline-diff replay without being rewritten as standalone realized feedback.

### Observation target identity

- Changed observation timeline-diff rows with explicit planned-vs-realized target identity mismatch now derive branch-local observation-success feedback for the planned target.
- Matching target-identity rows remain report evidence only.
- These preserve planned/realized target IDs, result/status evidence, source/replacement activity, changed-field, and trust-boundary context.

### Observation product identity

- Changed observation timeline-diff rows with explicit planned-vs-realized collection, product, product selector set, payload, or instrument identity mismatch also derive branch-local observation-success feedback for the planned target.
- Matching product identity rows remain report evidence only.
- These preserve planned/realized collection/product/product-set/payload/instrument IDs, mismatch reasons, result/status evidence, source/replacement activity, changed-field, and trust-boundary context.

### Pointing / attitude

- Changed observation timeline-diff rows with explicit pointing/attitude target or mode mismatch, failed pointing/attitude status, or degraded pointing/attitude status now derive branch-local observation-success feedback.
- Nominal pointing rows remain report evidence only.
- These preserve planned/realized pointing and attitude identity, status, error, model/source, source/replacement activity, changed-field, and trust-boundary context.

### Lighting / eclipse

- Changed observation timeline-diff rows with explicit realized eclipse overlap or degraded/eclipsed lighting condition/detail evidence now derive branch-local observation-success feedback.
- Nominal sunlit rows remain report evidence only.
- These preserve planned/realized lighting condition, lighting detail/model/confidence, eclipse-overlap fraction/duration, source/replacement activity, changed-field, and trust-boundary context.

### Target priority

- Changed observation timeline-diff rows with replacement, source, or top-level target priority at or above the branch policy threshold derive branch-local `target_priority_feedback`.
- Low-priority target changes remain report evidence only.
- These preserve target geometry, objective metadata, source activity, timeline ID, changed fields, and trust-boundary context.

### Command rows

- Changed timeline-diff command rows — including provider-shaped `planned_contact` or `contact` rows with command, uplink, or health-check direction — with failed command-result, success-factor, replacement-status, or typed status-transition evidence can derive command-success feedback branches.
- These preserve source/replacement activity IDs, timing, changed fields, provider command-result and realized-status evidence, status-transition category/review metadata, and trust-boundary context.

### Command routing identity

- Changed command timeline-diff rows with explicit planned-vs-realized direction, ground-station, or source-window mismatch also derive branch-local `command_success_feedback`.
- Matching successful command rows remain report evidence only.
- These preserve command routing identity, source/replacement activity IDs, timing, changed fields, result/status evidence, and trust-boundary context.

### Resource margins and availability

- Changed timeline-diff rows with replacement, source, or top-level low fuel, power, storage, downlink, or thermal margin evidence at or below the row/policy threshold can derive branch-local `resource_margin_pressure` events.
- Thermal margin can also be deterministically derived from externally supplied measured/actual temperature and declared operating-temperature bounds, **without adding thermal propagation or subsystem simulation**.
- Healthy changed margins remain report evidence only.
- Payload, antenna, or spacecraft availability evidence set false can derive branch-local `resource_availability_constraint` events.
- Explicit planned-vs-realized resource identity mismatches now also replay as branch-local resource-availability constraints for the planned activity's resource class:
  - observation resources map to payload availability,
  - contact/command resources map to antenna availability,
  - maneuver resources map to spacecraft availability.
- These preserve planned/realized resource IDs, mismatch status, source/replacement activity IDs, timing, changed fields, temperature/bound/status/model/source context for thermal rows, degraded/mode context, resource-filter suppression behavior, and trust-boundary context.

### Maneuver rows

- Changed timeline-diff maneuver rows — including typed `impulsive_burn` activity diffs — with failed maneuver-result, success-factor, replacement-status, or typed status-transition evidence can derive maneuver-success feedback branches.
- Rows with replacement/source maneuver execution-uncertainty maps or missing uncertainty status can derive maneuver-execution-uncertainty feedback branches.
- These preserve source/replacement activity IDs, timing, changed fields, provider maneuver-result, realized-status, covariance/source evidence, status-transition category/review metadata, maneuver-key-scoped operational feedback provenance counts, and trust-boundary context.

## Transition-application report replay

- Prior `source_timeline_transition_application_report` or `timeline_transition_application_report` applications feed the same timeline-diff branch-local refresh derivation, plus `timeline_transition_application_report.v1` applications embedded in prior `source_result_artifact` / `result_artifact` wrappers.
- These preserve `application_status`, selected-activity context, application source evidence, and report or wrapper trust-boundary provenance.
- Operator-review and Cadence-import source application rows now also synthesize `timeline_transition_application_report.v1` source-report provenance with reviewed/imported application paths and row-derived status, decision, and action counts, plus duplicate timeline-identity collision and scope counts.

direct

# Partial, Near-Term, Later, and Out-of-Scope

Status: **partial**.

## Persistent identity, timeline summaries, and diffs

- Persistent identity across replans now exists in V2/V3 repair artifacts.
- V1 has a schema-validated operational timeline summary.
- Standalone timeline diffs can compare activity lists by timeline identity and flag direction plus dependency/exclusivity changes for review.
- Diff summaries expose added/removed/changed/unchanged timeline ID sets, duplicate identity IDs, and invalid source/replacement input IDs for adapter routing.

## Transition-decision and integrity surfaces

The summary and transition helpers now expose:

- A single-activity transition-decision surface.
- A compact public timeline-integrity summary for dependency/exclusivity review rows and row-derived routing ID sets.
- Discoverable candidate-rejection and protection-decision facade metadata.
- Normalized lifecycle status and approval strings, including whitespace or hyphen separators, before classifying typed status/approval transitions or protection decisions.
- Selected-activity integrity review for single transition applications.

Single-activity timeline-identity changes are always marked review-required because they alter the durable repair/review/import join key.

**Transition-application count maps** now export the same canonical decision, application-status, operator-action, transition-type, and transition-category vocabularies published by `Timeline.capabilities/0`. Executable validation enforces those count maps as non-negative integer summaries before comparing them to application-derived counts. Selected activity and selected application timeline-integrity issue counters also carry the same non-negative integer schema/executable contract.

## Command/contact and realized feedback semantics

- The summary and feedback builders now emit typed command/contact and realized feedback review semantics, including contact throughput deltas and command/contact success fields.
- A dedicated artifact-only command-window report covers command/tracking/uplink review boundaries.
- Timeline-diff required-operator actions are now schema-visible and executable-validation backed, so added/removed/protected/integrity transition reviews cannot persist provider-specific action strings.

## Reconciliation of provider result evidence

Reconciliation now:

- Preserves explicit provider `contact_success` and `command_success` flags, including trimmed case-insensitive JSON-style booleans, over status-derived defaults.
- Derives unsuccessful completed commands from terminal provider `command_result` values such as `rejected`.
- Treats terminal provider `contact_result` values such as `dropped` as contact-success evidence for timeline-feedback and V3 strategy handoff.
- Accepts provider `observation_result` aliases for timeline-feedback rows and V3 observation-success handoff.
- Accepts provider `maneuver_result` aliases for timeline-feedback review/import rows and V3 maneuver-success handoff.

Both timeline-feedback and V3 strategy derivation normalize whitespace/case, whitespace-or-hyphen separators, comma-separated, and list- or map-valued provider result aliases, with failure winning over success in mixed evidence, while emitting schema-safe string result fields for review/import handoff. `Policy.capabilities/0` advertises the provider-result map keys used for action-rule matching.

**Precedence and provenance:**

- Realized maneuver outcomes take precedence over planned maneuver-confidence factors.
- The same provider `contact_result` and `observation_result` are preserved as review/import handoff evidence on realized-feedback, command-window, contention, station-calendar, contact-suppression, resource-suppression, and allocation rows.

## Terminal exceptions and completion outcomes

- Operational timeline `cancelled` and `rejected` provider statuses are treated as terminal exceptions requiring review.
- Executed realized feedback is recorded as a completion outcome.
- Completed/executed feedback is kept for planned work that was already status- or approval-policy-blocked or rejected, routed through the same resolve actions instead of record-only completion imports.
- Cancelled/rejected feedback is routed through status-specific exception review after trimming and case-normalizing provider status strings and normalizing whitespace/hyphen separators.
- Realized-only uplink contacts are treated as command feedback, with `TimelineFeedback.capabilities/0` advertising the command-contact direction set used for that classification.
- Completed-but-unsuccessful command or contact feedback, plus completed realized activities with partial `completed_fraction`, are routed to operator review.

## Partial completion-fraction grading

- Completed command/contact rows with partial `completed_fraction` now also emit explicit success-factor evidence sourced to `realized_activity.completed_fraction`, so V3 operational-feedback handoff can calibrate future command/contact confidence while preserving the review requirement.
- V3 branch-local command/contact refresh now replays those completed-fraction factors from prior `timeline_feedback_report.v1` operational-feedback provenance with per-key trust-boundary evidence, instead of collapsing mixed-source reports into anonymous feedback.
- Partial command/contact rows are graded through explicit completion or throughput evidence for operational-feedback success rates, instead of being flattened into binary failures when the provider has not supplied an explicit unsuccessful result.
- Realized observation rows that provide `completed_fraction` but not an explicit observation success factor now convert that fraction into artifact-level `observation_success_factor` evidence while preserving an explicit source label.
- Completed observation rows with provider `observation_result` failure aliases override status-derived success with `realized_activity.observation_result` factor provenance.

## Integrity-gated feedback rows

- Realized-feedback rows whose planned activity has dependency cycles, dependency ordering, exclusivity, or opt-in missing-dependency integrity issues are review-gated as `review_timeline_integrity` before record-only completion handoff, and preserve the concrete cycle ID arrays through feedback-derived review/import rows.

## Preserved context across review and import rows

Feedback-derived operator-review and Cadence-import rows now preserve:

- Match strategy, planned/realized timeline IDs, realized activity IDs and types.
- Top-level realized provider/source-quality/adapter/external ID/schema contract/trust-boundary context.
- Source-window type, source planned/realized activity rows.
- Planned operator-action context, planned Cadence import ID/type/contract.
- Nested realized timeline identity when provider feedback supplies a timeline ID for adapter correlation.

**Typed activity context** now preserves:

- Contact-success, command-success, observation-success, and maneuver-success feedback factors and source labels.
- Observation lighting/eclipsing evidence, source-window and command-window provenance labels, and schema-validated nested source-window boundary evidence.
- The explicit candidate-derived, operator-supplied, and unvalidated urgent-placeholder markers for strategy evidence.

This applies across operational timeline, timeline feedback, timeline diff, operator-review, and import rows, alongside:

- Planned/actual throughput aliases, throughput delta and completion fraction, including actual data-rate plus duration provider rows before deriving station-throughput feedback.
- Resource identity, product identity.
- Planned/actual data-volume evidence including delivered-volume aliases, delta, and completion fraction.
- Collection/delivery latency evidence including collection end time, planned and actual delivery time, max latency, planned/actual latency, latency delta, and latency margin across operational timeline, timeline diff, operator-review, and Cadence-import rows.
- Declared pointing/attitude context including pointing mode, pointing target, boresight axis, off-nadir/slew angles, pointing error/status/model/source/confidence, explicit attitude mode/target, roll/pitch/yaw, attitude error/status/model/source/confidence, and planned-versus-realized pointing target/mode/delta fields in timeline feedback, operator-review, and Cadence-import rows.

## Link-profile and link-quality review gating

- Planned-versus-realized link-profile evidence — including protocol, frequency band, modulation, coding, polarization, and data-rate deltas, with MB/s provider aliases converted to Mbps — now review-gates completed contact feedback when provider telemetry no longer matches the planned link configuration, so station-throughput and contact-success feedback cannot be applied silently across a different RF profile.
- Explicit realized link-quality failure evidence — including negative link margin, lost carrier/symbol lock, and low-margin/degraded/failure status aliases — also review-gates completed contacts and excludes them from automatic operational-feedback rollups.

## First-class mission-plan and study-manifest fields

- Typed `MissionPlan.Activity` inputs and `study_manifest.v1` mission-plan activities preserve declared product data-volume, required downlink, collection/delivery latency, planned/actual throughput, resource source/trust, provenance, blocking dimension, margins, battery, availability flags, degraded/mode state, incompatible/suppressed activity types, target-priority evidence, feedback success/result evidence, link profile/quality, pointing, attitude, thermal, lighting/eclipsing, and provider-declared observation/product quality evidence as first-class fields, instead of forcing manifest authors to hide it in metadata.
- Common provider-style volume, delivery, throughput, RF/link, resource availability, attitude, temperature, lighting, observation-quality, and command-window aliases normalize at typed activity ingress.
- First-class `attitude` activities copy pointing aliases into explicit attitude context when canonical attitude fields are absent.
- The study-manifest schema and loader now expose explicit attitude mode/target, roll/pitch/yaw, attitude error/status/model/source/confidence fields rather than relying on pointing aliases alone.

## Thermal and maneuver delta-v evidence

- Declared/measured thermal evidence with zone identity, operating bounds, derived margin, and status/model/source/confidence is preserved across the same timeline, diff, review, and import surfaces.
- Planned-versus-realized maneuver delta-v vectors/magnitudes review-gate completed maneuver feedback when provider delta-v differs from the planned burn, with resource identity mismatches included in row-level `identity_mismatch_fields` summaries preserved through operator-review and Cadence-import rows, so adapter queues can route realized variance reviews directly instead of scanning each planned/realized match field.
- Executable validation enforces stable-ID syntax for planned and realized identity fields at the feedback, review, and import boundaries.

## Maneuver execution-uncertainty

- Timeline-feedback maneuver rows now preserve planned and realized `execution_uncertainty` maps with derived timing and delta-v 3-sigma fields in both activity contexts.
- They select declared provider uncertainty over planned uncertainty for top-level feedback/review/import rows.
- They keep missing maneuver uncertainty explicit when neither side declares it.
- Nested timing/source/model/delta-v uncertainty fields are covered by exported JSON Schema and executable validation, and report-level declared/missing counts are validated against emitted rows.

## Observation target-priority and image/product quality

- Timeline-feedback reports now publish observation target-priority overrides into their `operational_feedback` handoff when realized observation feedback declares target priority, and candidate refresh consumes those derived overrides into branch-local observation scoring.
- Numeric realized image/product quality scores now feed the same `operational_feedback.observation_success_rate` handoff when no explicit observation success factor or provider result label is present, and explicit observation-success JSON-style booleans are normalized before V3 operational-feedback derivation, so branch-local refresh can consume declared product-quality feedback without a new high-fidelity image model.
- Standalone candidate refresh now applies the same fallback for cloud-cover and blur maps, plus target catalog quality fields, by using deterministic inverse-quality factors only when explicit success and image-quality scores are absent.
- Branch-authored `observation_success_feedback` events also accept image/product quality score aliases, preserving status/source, cloud-cover, and blur evidence while mapping the quality score to the existing observation-success feedback factor when the branch has not supplied one explicitly, and V3 branch-local refresh now forwards those normalized quality fields through `candidate_refresh.v1.operational_feedback` into refreshed observation candidates.
- Explicit `operational_feedback.image_quality_score` maps can also derive their own branch-local observation feedback branch, carrying target-keyed quality status/source, cloud-cover, and blur evidence with the generated refresh request, while high cloud-cover or blur feedback can derive the same branch using a deterministic inverse-quality success factor even when no provider image-quality score is present.
- Branch comparison, operator-review, and Cadence-import strategy-tradeoff rows summarize those branch-event quality fields for adapter routing, and selected strategy-recommendation review/import rows flatten the same branch-event quality summary instead of requiring adapters to reopen `source_recommendation.explanation`.
- Nested operator-review and Cadence import row schemas plus executable validation now enforce those list/count/stable-ID and unit-interval quality contracts.

## Provider-shaped identity objects

- Realized feedback normalization also accepts provider-shaped singular `target`, `station`, and `ground_station` objects as identity evidence.
- It emits canonical `target_id` / `ground_station_id` feedback rows and contexts for planned-vs-realized matching and operational-feedback handoff.

It advertises those identity objects in the exported `realized_activity.v1` JSON Schema, plus:

- Resource identity/source/trust/provenance, fuel/power/storage/downlink/battery margins, availability/degraded flags, activity suppression arrays.
- Declared pointing mode/target, boresight axis.
- Collection/product/payload/instrument identity, planned/realized/estimated data-volume fields, required downlink, delivery/latency fields, target priority.
- Contact/command/observation/maneuver success/result fields, success-factor source labels, and feedback weights.
- Maneuver delta-v vectors plus execution-uncertainty maps and 3-sigma timing/delta-v fields.
- Off-nadir/slew angles, pointing error/status/model/source/confidence, and explicit attitude mode/target, roll/pitch/yaw, attitude error/status/model/source/confidence.
- Declared/measured thermal zone, temperature, operating-bound, margin, status/model/source/confidence.
- Lighting condition/detail/model/confidence plus eclipse-overlap fraction/duration.
- Observation/product quality score/status/source, cloud-cover fraction, and blur score.
- Link protocol/band/modulation/coding/polarization, link margin/quality metrics, and planned/actual throughput.

## Thermal, pointing, attitude, and lighting across review/import rows

- Timeline-feedback planned and realized activity contexts plus row-level reconciliation now preserve the same thermal zone, planned/measured temperature, operating-bound, derived-margin, status/model/source/confidence evidence as operational timeline reports.
- Operational-timeline review/import rows and timeline-feedback realized-feedback review/import rows carry that evidence as top-level adapter-routeable fields.
- Operational-timeline review/import rows likewise lift pointing and attitude mode/target/error/status/model/source evidence, link protocol/band/rate/quality evidence, observation-quality scores, feedback weights, and maneuver result fields as top-level adapter metadata.
- They now also preserve planned and realized lighting/eclipsing evidence — such as eclipse-overlap fraction/duration, lighting condition/detail/model, confidence, image/product quality score/status/source, cloud-cover fraction, and blur score — through the same feedback, operator-review, and Cadence-import surfaces.
- Operational-timeline review/import rows now preserve artifact-only command authority and command-safety context from planned timeline rows — including authority/safety status, required authority, authorization, and safety-check fields — without granting authority, signing, uplinking, importing, mutating schedules, or executing commands.
- Operational-timeline review/import rows preserve row-derived activity precondition status, counts, precondition type arrays, and typed precondition rows across nested source rows, with schema validation rejecting stale copied precondition handoff values.
- Exported nested activity-context schemas declare those identity, throughput/completion, maneuver-uncertainty, observation-quality, and lighting/eclipsing fields instead of leaving the source/realized/replacement contexts opaque, including Cadence import manifest import/source/realized/replacement context fields for adapter-facing row validation, and allow lighting confidence to be either the qualitative sampled-eclipse label used by generated candidates or the numeric confidence used by provider feedback.

## Downlink demand handoff

- Partial/failed downlink feedback with required downlink evidence now publishes station-specific `downlink_demand_mb` handoff maps plus exact `downlink_demand_sources` lineage that derived V3 `downlink_demand_feedback` events preserve before candidate refresh consumes it as branch-local downlink-completion demand, directly and through V3 prior-repair strategy refresh branches.
- V3 mission-state realized observation data-volume telemetry — including provider-style delivered/received and estimated/planned aliases, plus partial/failed downlink telemetry with required-downlink evidence and actual-throughput/downlink/delivered/received aliases — derives the same default or station-specific demand branch without requiring callers to prebuild a timeline-feedback report.

## V3 strategy provenance and feedback facets

- V3 strategy operational-feedback provenance now records source-level input keys for feedback derived from mission-state realized telemetry, and `strategy_branch.v1` plus `strategy_recommendation.v1` explanation rows now expose typed feedback-adjustment factor fields plus branch-generated activity-source provenance instead of leaving the branch-local feedback model as an opaque object.
- Delayed or otherwise non-success telemetry rows emit only the feedback facets they actually support, so data-volume, target-priority, or throughput evidence no longer fabricates contact or observation success rates.
- Timeline-feedback reports can derive station-throughput feedback from required-downlink evidence when explicit planned throughput is absent.

## Provider result failure routing and status vocabulary

- Operational timeline reports route scalar, comma-delimited, list-valued, and map-valued provider result failure aliases on otherwise completed or executed contacts/commands to terminal-exception review, while preserving schema-safe `contact_result` / `command_result` / `observation_result` values through timeline rows, activity context, operator review, and Cadence-import handoff.
- Timeline-feedback realized statuses now share an exported schema-visible vocabulary with `realized_activity.v1`, with the additional `invalid` sentinel reserved for review-gated malformed feedback rows and executable validation rejecting unknown provider-specific status values in persisted feedback artifacts.

## Resource-margin and resource-availability feedback

- Timeline-feedback reports now also derive resource-margin and resource-availability operational-feedback maps from realized resource telemetry, preserving battery capacity, energy-used, and state-of-charge evidence while deriving planning-grade power margin from battery state of charge when explicit power margin is absent, and V3 strategy can consume those maps from a prior plan's source feedback report to derive resource-pressure refresh branches without raw telemetry rows.

## Operational-feedback provenance

- Timeline-feedback reports now publish `operational_feedback_provenance` with source report counts, row counts, feedback-kind, match-strategy, import-status, realized source-quality, protection-decision counts, input keys, and trust-boundary status for row-derived `operational_feedback`.
- `TimelineFeedback.capabilities/0` advertises the provenance, source count, input-key, realized-activity count, trust-boundary status, source quality-count, and excluded-count row semantics.

## Station-calendar evidence

- Timeline-feedback rows now also lift station-calendar availability, entry/direction, provider/provider-entry identity, overlap, reservation, reservation-expiration, trust-boundary, and source station-calendar evidence into source/realized activity contexts, operator review rows, and Cadence import rows, so provider-calendar feedback can be routed without unpacking nested activity payloads.
- `TimelineFeedback.capabilities/0` advertises accepted direct and source station-calendar capacity fraction/percent paths plus typed fraction/percent capacity-value metadata for station-capacity feedback context, and provider-result map keys used to derive contact, command, observation, and maneuver result labels.
- Operational timeline ingress now canonicalizes station-calendar availability, status, contention, reservation-match, overlap-availability, and nested source-calendar status tokens for case, whitespace, and hyphen differences before row, context, review, diff, or import handoff.

## Validation and protection-decision application

- Executable validation now checks timeline-feedback `model_limits` against `TimelineFeedback.capabilities/0`.
- Timeline diff, operator-review, and import rows preserve source/replacement protection-decision evidence for locked, approved, executed, and mutable activities.
- Public transition-application helpers now resolve a proposed source/replacement change into an artifact-only application plan that preserves protected source work, retains unchanged source activities, and withholds selected activities for review-gated timeline changes.
- A batch application report applies the same safe-selection semantics across a whole source/replacement timeline while preserving row counts and source diff evidence and rechecking the selected subset for dependency/exclusivity integrity when review-gated rows are withheld.
- Operator-review/Cadence-import helpers route review-required application rows through the existing timeline-diff review lane while preserving application status and selected safe-activity evidence.

**Caveat:** those semantics remain artifact-level conventions rather than a persistent operations timeline service.

## Near-Term

Status: **near-term**.

- Continue broadening typed activity context into richer feedback import packages beyond the current product/data-volume, latency, link profile/quality, observation-quality, lighting/eclipsing, pointing/attitude, thermal, command authority/safety, and resource/availability evidence.

## Later

Status: **later**.

- Timeline diffing, operator review products, persistent timeline identity, source-window traceability across replans, and execution feedback reconciliation.

## Out of Scope

Status: **out of scope**.

- Cadence UI timeline editing and final schedule execution.

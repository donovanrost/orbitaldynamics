# Timeline Feedback Reconciliation

`TimelineFeedback` reconciles planned activities with `realized_activity.v1` rows into schema-validated `timeline_feedback_report.v1` rows. Each report carries timing deltas, status counts, and an explicit typed status-transition object for planned-to-realized lifecycle changes, plus planned timeline protection decisions.

## Schema-visible counters

- **Report-level count maps** — `feedback-kind`, `match-strategy`, Cadence-import-status, `protection-decision`, uncertainty, exclusion, duplicate-feedback, and ambiguous-timeline counters are schema-visible as non-negative count maps with canonical enum keys for row status, feedback kind, match strategy, Cadence import status, and protection decision. Executable validation checks them against emitted rows.
- **Top-level counters** — planned, realized, and row counters, plus optional uncertainty, feedback-exclusion, ambiguous-timeline, and duplicate-realized counters, are also exported and executable-validated as non-negative integers.

## Reduced-capacity context

Station-calendar reduced-capacity context is lifted into feedback, review, and import rows from:

- declared fraction fields,
- contact-allocation capacity-pack fraction fields,
- provider percent aliases,
- nested model/context maps, and
- source station-calendar entry/overlap evidence.

## Variance thresholds

- Callers can declare a `timing_variance_threshold_s` reconciliation threshold. It promotes completed rows with larger start/end timing deltas into variance review/import gates while preserving the max delta and threshold on feedback, review, and import rows.
- Top-level `activity_type` is accepted as a realized-feedback activity-kind alias before reconciliation, so feedback, review, and import rows retain the same operational kind context as canonical `type`.

## Realized-activity normalization facades

The following facades expose the same report-compatible realized feedback normalization without requiring a full planned-vs-realized reconciliation report:

- `TimelineFeedback.normalize_realized_activity/2`
- `TimelineFeedback.normalize_realized_activities/2`
- `OrbitalDynamics.normalize_realized_timeline_activity/2`
- `OrbitalDynamics.normalize_realized_timeline_activities/2`

`TimelineFeedback.activity_state/3` and
`OrbitalDynamics.timeline_activity_state/3` expose the compact
`timeline_activity_state.v1` contract for callers that need a single
planned/realized activity-state artifact. The contract validates the
row-derived state status, row count, status/feedback/match/Cadence/protection
count maps, review IDs, and artifact-only no-mutation/no-command assumptions
against the embedded feedback rows. It also pins the timeline model-limit list
in executable validation and JSON Schema export.
`Timeline.dependency_impact_summary/3` and
`OrbitalDynamics.timeline_dependency_impact_summary/3` publish the same
timeline model-limit list in executable validation and JSON Schema export for
dependency/exclusivity impact handoffs.
`Timeline.integrity_report/2` and `OrbitalDynamics.timeline_integrity_report/2`
pin that same list for dependency/exclusivity integrity handoffs.

## Numeric-string normalization

- Clean numeric-string planned and realized feedback inputs normalize before row assembly for timing, throughput/data-volume, completion and confidence factors, resource and pointing telemetry, maneuver vectors, and execution-uncertainty evidence.
- `TimelineFeedback.operational_feedback/1` applies the same clean numeric-string handling when callers aggregate feedback directly from row maps.
- Malformed optional numeric strings remain missing evidence.

## Invalid-input preservation

- **Out-of-range / malformed unit-interval scalars** — out-of-range or malformed realized completion/success/observation-quality scalars are preserved as invalid realized-feedback sections on timeline-feedback, operator-review, and Cadence-import rows instead of being clamped into effective operational feedback.
- **Invalid planned activity inputs** — preserved as `review_invalid_activity_input` feedback rows.
- **Malformed realized feedback handoffs** — handoffs missing identity, carrying malformed provider IDs, or missing shape are preserved as `review_invalid_realized_feedback_input` rows with schema-stable synthetic review IDs, invalid-input reason, and source activity evidence through the embedded review/import artifacts, instead of failing before operator review.
- **Missing / unsupported provider statuses** — missing or unsupported realized provider statuses are preserved through the same invalid-feedback review/import gate instead of aborting reconciliation, with unsupported status values promoted for adapter routing. Malformed realized rows that still identify planned work are correlated back to that planned activity before review.
- **Negative / malformed feedback weights** — preserved as invalid realized-feedback sections and excluded from weighted aggregation until reviewed.
- **Invalid provider feedback scalars** — preserved as review-visible invalid sections rather than normalized into feedback, review, or import artifacts.

## Status derivation and lifecycle vocabulary

- **Match-state vs execution-outcome rows** — provider-shaped realized rows whose `status` is a match/correlation state and whose `realized_status` carries the execution outcome use that `realized_status` for feedback, typed status transitions, protection decisions, operator review, and Cadence import, while preserving the original match state as `feedback_status`.
- **Lifecycle-event-derived status** — realized rows may also derive terminal execution status from normalized lifecycle events such as `record_completion` and `record_failure`. Non-terminal lifecycle events remain invalid-feedback review rows.
- **Capabilities advertisement** — `TimelineFeedback.capabilities/0` advertises the lifecycle-event to realized-status map, terminal completion/failure status families, and match feedback statuses.
- **Accepted provider statuses** — the realized feedback contract accepts executed, cancelled, and rejected provider statuses.

## Executable validation

Executable validation now:

- enforces non-negative integer top-level counts and pins the feedback-specific
  model-limit list in runtime validation and JSON Schema export,
- validates `status_counts` against row statuses,
- validates row-derived `feedback_kind_counts`, `match_strategy_counts`, `cadence_import_status_counts`, and `planned_protection_decision_counts`,
- advertises those summary/count semantics through `TimelineFeedback.capabilities/0`, and
- checks planned, realized, row, duplicate, and ambiguity totals against the emitted feedback rows.

This means runtime gates match exported JSON Schema and adapter queues can route feedback without recounting rows. Duplicate/ambiguity and execution-uncertainty diagnostic count row semantics are also advertised for catalog consumers.

**Protection-decision payload validation** — nested protection-decision payloads in feedback, review, diff, and import rows share executable validation for stable activity/timeline IDs, lifecycle status, lock/approval flags, timeline identity, decision enum, category enum, and reason.

## Embedded operator-review and Cadence-import artifacts

- **`operator_review_package.v1`** — emitted for completed, variance, exception, missing-feedback, unplanned-feedback, and duplicate-provider-feedback review/import rows.
- **`cadence_import_manifest.v1`** — turns those realized-feedback review rows into deterministic record/review adapter actions and status counts, while preserving planned Cadence import status and the same typed status-transition and protection-decision evidence.

## Identity handling

- Malformed planned or realized product-ID array entries, including non-stable strings, are ignored before product match classification instead of becoming phantom mismatch IDs.
- Absent or malformed optional collection/payload/instrument identities remain absent rather than stringified.
- Completed contact or command feedback whose planned activity is missing a Cadence import identity remains review-gated as `prepare_cadence_import` with `blocked_missing_cadence_import` manifest status, instead of becoming a record-only completion import.

## Derived operational feedback for V3 handoff

The report emits schema-typed `operational_feedback` derived from realized rows for V3 strategy/candidate-refresh handoff, including:

- contact success,
- station throughput,
- observation success,
- command success,
- maneuver success,
- maneuver-execution uncertainty,
- observation-quality score/status/source,
- cloud-cover,
- blur,
- downlink-demand maps, and
- station-keyed downlink-demand context derived from realized observation/data-latency evidence.

Scoped downlink-completion context is flattened into branch risks, comparison rows, selected-recommendation risk drivers, operator-review rows, and Cadence import manifest rows for adapter routing.

### Feedback weighting

- Optional nonnegative `feedback_weight` / `feedback_weight_source` evidence is preserved through feedback, review, and import rows and applied as deterministic weighted averages for success, throughput, and target-priority feedback, plus weighted additive downlink-demand feedback.
- Zero weights are accepted as explicit no-confidence rows and excluded from effective aggregation, weighted-row counts, and feedback-weight source summaries.
- Negative or malformed feedback weights are preserved as invalid realized-feedback sections and excluded from weighted aggregation until reviewed.

### Explicit realized factors and mismatch review

- Explicit realized success factors drive operational feedback ahead of planned confidence factors when provider execution evidence is present.
- Planned/realized contact direction, station, or source-window mismatches, plus observation target mismatches, are marked review-only for derived `operational_feedback`, so mismatched telemetry cannot silently alter branch scoring inputs while still flowing through operator review and Cadence import review rows.

## Candidate refresh

- Branch-local candidate refresh preserves those target-keyed quality maps on refreshed observe candidates. It can use explicit image-quality scores, then inverse cloud-cover or blur scores, from either operational feedback maps or standalone target catalog quality fields as observation-success factors when no direct success-rate feedback is supplied.
- V3 branch-generated refresh requests carry target-keyed observation-quality score/status/source, cloud-cover, and blur feedback from realized activities, explicit operational-feedback quality maps, and branch-authored observation feedback into refreshed observe candidates, so strategy branches no longer need hand-authored refresh artifacts to retain provider quality evidence.
- These operational-feedback maps are schema-visible on timeline-feedback, candidate-refresh, and strategy artifacts instead of remaining opaque nested objects.

## Facade and provider source-quality

- The top-level `OrbitalDynamics.timeline_operational_feedback/1` facade accepts both string-keyed JSON artifacts and atom-keyed Elixir report maps for that derived handoff.
- Realized provider source-quality labels are normalized from `source_quality`, `quality`, or `quality_level` and preserved as `realized_source_quality` through timeline-feedback, operator-review, and Cadence-import rows.
- Provider-supplied completion fractions and contact/command/observation/maneuver success factors are accepted only inside executable schema bounds, and provider feedback weights are accepted only when nonnegative.

## Preserved feedback-row context

Feedback rows preserve:

- command/contact context including direction, ground-station ID, and source-window lineage,
- score terms, estimated throughput, target-priority and observation-feedback factors,
- Cadence import status,
- command success/result and contact success/result,
- planned-versus-actual throughput deltas,
- planned-versus-actual data-volume deltas,
- product/collection identity, payload/instrument IDs, planned timeline identity, and
- planned-versus-realized match statuses for target, collection, product, payload, and instrument identity (so completed observation/product feedback mismatches are review-gated instead of becoming record-only imports),
- dependency/exclusivity stable-ID arrays,
- timeline-integrity review evidence from the shared typed activity normalizer, and
- normalized source planned and realized activity rows.

**Station-ID normalization** — provider-shaped realized contact `station_id` normalizes into canonical `ground_station_id` report/context fields while the original realized row remains intact.

**Match strategy** — feedback rows preserve the match strategy when external execution rows identify the planned item by `planned_activity_id` or timeline identity instead of reusing the plan activity ID.

## Realized activity-context maps

Realized activity-context maps preserve:

- provider-declared planned IDs, matched planned IDs, match strategy, and ambiguous planned-ID evidence, and
- provider/import provenance fields such as source, provider, adapter, external ID, schema contract, trust boundary, timestamps, provenance, and metadata for review/import correlation.

Malformed non-object realized `cadence_import` context is preserved as `review_invalid_cadence_import` evidence instead of crashing feedback reconciliation.

## Duplicate and ambiguous realized rows

- **Duplicates** — duplicate realized rows for the same planned activity are retained as all matched realized IDs and normalized realized rows, counted in duplicate-feedback report fields, and review-gated before import.
- **Ambiguity** — realized rows whose timeline IDs match multiple planned activities are retained as ambiguous realized-only feedback with all possible planned activity IDs and source rows preserved for operator review, rather than arbitrarily attached to one planned item.

## Repair and branch integration

- Completed contacts with realized throughput shortfalls are routed to contact-variance review instead of record-only completion.
- V2 repair and V3 branch-repair artifacts embed timeline-feedback reconciliation when realized activities are supplied. Matched/realized-only feedback rows are lifted into repair/strategy operator-review packages and Cadence import manifests with reusable source and realized activity-context maps, including the same match-correlation fields.
- Realized-only command-directed contact feedback is classified with command semantics while retaining its contact/station context.
- CandidateRefresh timeline-feedback source and replay summaries preserve row-derived Cadence-import status counts before stale aggregate fields, so branch-local import-review pressure remains visible without reopening full timeline-feedback rows.
- CandidateRefresh operational-timeline source summaries lift row-derived operational-kind, activity-status, approval-status, required-action, and Cadence-import-status maps alongside the replay helper, so stale operational-timeline aggregate maps cannot steer source-report routing.

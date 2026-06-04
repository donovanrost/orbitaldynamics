# Candidate-Diff, Strategic Additions, and Downlink-Completion Staging

## Objective-satisfaction replay into refresh objectives

`source_objective_satisfaction_report` / `objective_satisfaction_report` rows, result-artifact embedded `objective_satisfaction_report.v1` rows, and preserved operator-review or Cadence-import objective-satisfaction rows now replay into executable candidate-refresh objectives:

- Non-passing downlink-completion rows become `downlink_completion` objectives.
- Target coverage/commitment rows become target revisit/coverage objectives.
- Collection-latency rows become `collection_latency` objectives.
- Met/selected rows remain report evidence only.

## Branch-local refresh from preserved review and import packages

### Cadence-import manifests

Prior `cadence_import_manifest.v1` rows that preserve source review rows can also feed the same branch-local refresh derivation as operator-review packages. This includes:

- Timeline-diff, including nested or flattened timeline-diff rows.
- Timeline-transition-application.
- Score-term, including nested or flattened score-term rows.
- Objective, including nested or flattened objective-satisfaction and objective-tradeoff rows.
- Constraint.
- Resource, including nested or flattened resource-projection rows.
- Link-capacity, including nested or flattened link-capacity rows.
- Contact-contention recommendation.
- Contact-allocation, including nested or flattened contact-allocation rows.
- Direct Cadence import `source_recommendation` rows and flattened contact-contention recommendation rows for contact-contention resolution.

This works without requiring the original review package or source report to be resubmitted.

### Operator-review packages

Prior `operator_review_package.v1` rows that preserve source objective-satisfaction, objective-tradeoff, score-term, constraint, timeline-diff (including nested or flattened timeline-diff rows), timeline-transition-application, resource-projection (including nested or flattened resource-projection rows), link-capacity (including nested or flattened link-capacity rows), contact-contention recommendation, or contact-allocation rows can now feed the same branch-local refresh derivation without requiring the original source report to be resubmitted.

## Branch-event trust boundary and provenance

Non-resource derived operational-feedback branches now preserve the same unambiguous source trust boundary on these branch events:

- station-throughput
- contact-success
- observation-success
- maneuver-success
- command-success
- downlink-demand
- target-priority

Strategy branch-event contracts now expose and validate branch-event `trust_boundary` and `provenance` fields instead of leaving them as opaque extra JSON.

Branch-comparison, operator-review, and Cadence-import rows now also surface row-derived `branch_event_trust_boundary_status_counts` so review queues can distinguish declared-boundary branch drivers from missing-boundary branch drivers without reopening nested event payloads. Executable validation requires those counts to use only `declared` / `missing` keys and to add up to the row's `branch_event_count`.

## Resource-availability overrides

`operational_feedback.resource_availability_overrides` can derive a branch-local payload/antenna availability refresh that suppresses generated observation or downlink candidates through the same resource-filter contract, and exposes the availability risk in branch-comparison rows.

**Spacecraft-level degraded or unavailable overrides** can also:

- Derive a `degraded_spacecraft` event.
- Suppress incompatible generated candidates.
- Lower branch-comparison spacecraft, payload, and antenna availability according to the event's incompatible activity types.

Multiple independent same-spacecraft degraded records retain separate derived branches instead of collapsing behind the spacecraft-only branch ID.

**Event-level trust boundaries** — explicit branch resource events preserve event-level trust boundaries across merged resource-summary overlays, so downstream resource-filter review/import rows can retain provider provenance even when multiple events affect the same spacecraft.

**Schema typing** — exported JSON Schemas now type the full availability override payload for the canonical `resource_availability_overrides` field and the `availability_overrides` alias, including spacecraft availability, degraded mode, and incompatible/suppressed activity-type arrays.

**Public struct exposure** — the public `OperationalFeedback` struct and strategy normalizer expose the same downlink-demand, target-priority, resource-margin, observation-quality, and merged availability override fields used by JSON requests, including canonicalization of struct-style `payload_available?`, `antenna_available?`, and `degraded?` availability flags before branch derivation.

## Downlink-completion staging

Downlink-completion gaps can also consume branch-generated access candidates as approval-required strategic additions when a non-overlapping objective-matching downlink candidate exists. This covers:

- Station/scenario/time-window scoped downlink-completion objectives.
- Collection/product/payload/instrument scoped downlink-completion objectives whose explicit downlink data identity selectors must match planned and candidate downlinks plus the objective-satisfaction and branch-comparison contact-count evidence.
- Required downlink data-volume objectives.
- Multiple scoped downlink-completion objectives that derive independent branch-local refresh branches instead of only considering the first objective, with duplicate provider objective IDs disambiguated by station/time/data scope instead of hiding one scoped branch.
- Provider-shaped station/time candidates that omit explicit type or direction, by normalizing them into canonical downlink activity fields.

## Collection-latency objectives

Collection-latency objectives can derive one branch-local downlink-relief request per observation that lacks an on-time follow-on downlink or enough required downlink data volume inside the required latency window. They:

- Ignore realized missed/failed downlinks as latency-satisfying contacts.
- Preserve on each branch event the objective ID, source observation ID, missed downlink ID, realized status, latency requirement, required downlink volume, currently planned latency-window volume, and collection/product/payload/instrument identity selectors.

Explicit collection/product/payload/instrument identities on planned or realized downlinks are respected when deciding whether they satisfy that scoped latency objective. Derived branch IDs are objective-scoped when multiple latency objectives apply to the same observation.

### Latency reporting

- Branch `objective_satisfaction` summaries now include collection-latency rows that report per-observation latency, planned latency-window volume, contact count, and satisfied/unsatisfied status.
- `branch_comparison_report.v1` rows flatten collection-latency ratio and satisfied/unsatisfied counts for branch scan and Pareto comparison.
- Strategy recommendation explanations include those objective-satisfaction summaries for the recommended branch, with operator-review and Cadence-import strategy rows preserving that recommendation explanation as source context.

## Repair reasons and realized-feedback pressure

Validated downlink additions carry objective- or pressure-specific repair reasons for downlink completion, collection-latency relief, storage relief, and downlink-margin pressure, so operator-review rows explain why a contact was staged.

**Realized missed/failed downlink feedback** in mission state now:

- Reduces effective planned contact count and effective planned downlink data volume.
- Derives a downlink-completion refresh branch.
- Carries source activity/status context into the branch event, with sparse downlink rows using prior-plan context only when the planned activity ID is unique.

## Mission-state resource-pressure branches

- **Low storage margin** can now derive the same downlink-relief branch, require one additional contact beyond the current planned count when needed, preserve the storage-pressure reason on the branch event and staged candidate feasibility, and carry a resource-pressure overlay so branch-local refresh can suppress storage-constrained observation candidates through the existing resource-filter contract.
- **Low downlink margin** also carries a resource-pressure event on the same constrained branch so branch-local refresh can suppress downlink candidates through the resource filter when policy requires more downlink margin.
- **Low fuel margin** now carries a resource-pressure event on the fuel-preservation branch so branch-local refresh can suppress candidates through the existing resource-filter contract.
- **Low power margin** can derive a power-constrained branch whose branch-local refresh carries a resource-pressure event through `resource_summary.v1` and the existing resource filter.
- **Payload or antenna unavailability** can derive payload- or antenna-constrained branches whose branch-local refreshes suppress generated observation or downlink candidates through the same resource-filter contract.
- **Branch-local degraded-spacecraft events** now carry the same resource-impact semantics into branch comparison instead of only suppressing activities.

## V2 repair and candidate-diff replacement

V2 repair consumes `candidate_diff_report.v1` semantic replacement links. It:

- Prefers the declared `replacement_candidate_id` during missed-contact and failed-observation repair when it matches the repaired activity.
- Preserves the semantic diff row, including budget-dropped replacement metadata, in replacement repair metadata.

Ambiguous candidate-diff replacement matches are preserved as explicit metadata instead of collapsing duplicate invalidated/replacement rows, while still retaining budget-dropped replacement IDs.

**Standalone candidate-refresh handoff** now preserves invalidated candidate-diff rows and retained candidates with semantic-change reasons as review/import gates instead of only as nested refresh evidence, exposes stale/unknown freshness as review/import gates, and lifts budget-dropped candidate evidence into review/import gates.

## Provider-shaped candidate normalization

Prior provider-shaped contact candidates that use `station_id` or nested `station` / `ground_station` identity objects plus either `type: contact` with downlink direction or no explicit type/direction normalize into the same candidate-diff semantic key as refreshed downlinks. In this case:

- `start_s` / `end_s` aliases become canonical timing fields.
- Top-level `activity_type` is accepted as a prior-candidate type alias for exported timeline-style rows.
- Command-result-shaped rows are still review-gated as invalid prior-candidate inputs.

**V2 repair and V3 downlink-completion staging** also accept top-level `activity_type` as the planned/candidate kind alias before provider inference, so explicit alias-only downlinks normalize into canonical downlink/station fields while command/tracking rows are not inferred as downlinks.

**V3 downlink-completion staging** also accepts provider-shaped station/time candidates without explicit type or direction, including nested `station` / `ground_station` identity objects, by normalizing them into canonical downlink/station fields. This avoids false stale/new churn or missed strategic additions from provider shape differences while still surfacing operational feedback or station-state changes on retained rows.

## V3 strategic additions and approval context

V3 strategic additions sourced from refreshed candidates now also preserve the semantic diff row in repair and feasibility metadata before urgent-target or downlink-completion staging rewrites activity IDs.

**Staged feasibility provenance** — staged strategic-addition feasibility now also preserves branch-event feedback provenance, including `feedback_source`, `feedback_scope`, `trust_boundary`, derivation reasons, and source activity/timeline identity. Strategic-addition approval requirements expose the same fields in `activity_context`.

**Policy matching** — policy action rules can match that feedback source/scope, trust boundary, and source event type across branch events, approval-requirement context, and staged feasibility.

**Review/import lift** — strategy recommendation explanations and `operator_review_package.v1` approval rows lift the same candidate-diff context plus ambiguity and budget-drop match fields for review/import gates, including plural `objective_ids` from replacement events when a provider row ties the replacement to multiple objective records.

**Approval activity-context schema typing** — approval activity contexts now schema-type the replay source event, source branch, source timeline, feedback, trust-boundary, derivation, and source-event provenance fields used for review routing, including nested source-event provenance trust-boundary labels, plus staged candidate score terms, source window, feasibility status, repair reason, and candidate-diff changed-field evidence.

Nested source-window evidence is checked for stable identity and timing fields. Strategic-addition approval requirements now carry staged candidate activity context including timing, source-window, score, target-priority, and observation-feedback evidence through operator-review and Cadence-import rows.

## Candidate-diff metadata and changed-field routing

- Standalone candidate-refresh candidate-diff handoff rows now preserve candidate-activity source-target metadata and target latitude/longitude/minimum-elevation fields plus target-priority value/source/objective evidence through both operator-review and Cadence import schemas, and generated candidate-diff rows now carry the same metadata at the producer.
- Semantic candidate-diff rows also carry deterministic `semantic_change_details` before/after value evidence through producer, review/import, and V3 replay surfaces, plus sorted `candidate_diff_changed_fields` and count summaries derived from that evidence, including station-reservation hold expiration changes, so standalone candidate-diff reports remain self-contained and review queues can route by changed field.
- Refreshed candidate station-calendar contexts also preserve reservation expiration seconds from unambiguous reservation rows, ambiguous overlaps, and provider-contention source reports.

## V3 scope and combined branches

- V3 carries candidate-source scope in branch assumptions/provenance.
- Opt-in branch generation can synthesize a combined mission-state branch from the individual derived what-ifs for joint-case review.

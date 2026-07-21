# Lifecycle, Roadmap, and Closing

Status: **`partial`**.

## Branch-specific refresh execution

- Branch-specific refresh can now execute inside V3 from explicit requests or rich mission state.
- Candidate refresh has thin resource and ground-network availability/margin filters that branch-derived refresh now exercises for:
  - station outage, reservation, capacity, synthesized mission-state resource summaries, and explicit resource summaries;
  - degraded-spacecraft plus low-fuel, low-power, low-storage, low-downlink, and low-thermal resource-pressure;
  - spacecraft-unavailable, payload-unavailable, and antenna-unavailable events.

## Promoting and replaying provider-calendar evidence

- Branch derivation can also promote prior station-calendar affected-contact rows into the same station outage, reservation, and reduced-capacity event path without requiring operators to re-enter provider calendar intervals by hand.
- It can replay preserved provider-calendar contention groups into branch-local reservation/outage/reduced-capacity refresh events from their source calendar entries, whether they are still on the original station-calendar report or have already moved through operator-review or Cadence-import source rows.

## Explicit resource summaries and branch events

- Explicit resource summaries also drive the corresponding low fuel, storage, downlink, power, thermal-margin, degraded-state, payload-availability, and antenna-availability branch derivation and branch-comparison resource risks.
- Explicit branch `resource_margin_pressure`, `resource_availability_constraint`, and `degraded_spacecraft` events are carried into branch-generated `candidate_refresh.v1` operational-feedback overrides, so refreshed resource filters preserve feedback input-key and trust-boundary evidence.

### Normalization of scalar values and labels

- Atom- or string-style incompatible activity scalar values and lists are normalized to deterministic string arrays for mission-state spacecraft states, resource-summary degradation rows, degradation entries, and branch events.
- JSON-style degraded and availability booleans, including `"1"` / `"0"`, are normalized before repair suppression.
- String-normalized degraded-mode labels and spacecraft/scenario identity are preserved in derived branch events, repair snapshots, feedback keys, resource overlays, and risk rows.
- Branch-authored `suppressed_activity_types` are canonicalized into `incompatible_activity_types` in emitted branch events.

## Feedback branches

- **Station-throughput and contact-success feedback branches** — including station-throughput feedback from realized downlink required-demand evidence when explicit planned throughput is absent.
- **Observation-success and target-priority feedback branches** — including target-priority overrides derived from realized observation telemetry rather than planned activity context alone.
- **Mission-state embedded operational-feedback branch derivation** — with top-level request feedback taking precedence.
  - The public `%MissionState{}` struct now carries the same target/station catalogs, accepted planning state, candidate-refresh defaults, and timeline-feedback handoff fields as map-shaped strategy requests.
  - Mission-state embedded `timeline_feedback_report.v1` artifacts can now feed the same `operational_feedback` merge/provenance path, preserving the source report's nested operational-feedback trust-boundary provenance, without requiring callers to wrap realized feedback in a prior repair artifact first.
- **Resource-availability feedback branches.**
- **Thermal-margin feedback branches** — from clean numeric-string operational-feedback overrides, source timeline-feedback reports, and realized resource-telemetry rows when a thermal branch-generation threshold is declared.
- **Maneuver-execution delta provenance.**
- **Station-throughput feedback** — from explicit inputs or realized contact telemetry.
- **Contact-success feedback** — from explicit inputs or realized contact status.
- **Observation-success feedback** — from explicit inputs or realized observation status.
- **Maneuver-success feedback branches and accepted-state maneuver execution deltas** — from explicit inputs or realized maneuver status.

### Partial realized rows and aliases

- Partial realized contact, observation, maneuver, and command rows use `completed_fraction` as the feedback factor when supplied, including:
  - completed/executed success;
  - delayed/partial confidence;
  - canceled/cancelled/rejected terminal failure aliases;
  - normalized provider `contact_result` / `command_result` / `observation_result` aliases from timeline feedback.
- **Target-priority feedback.**
- **Missed/failed/canceled/cancelled/rejected observation feedback** — as target-revisit demand while suppressing collection-latency downlink relief for observations that never produced collected data, including completed provider observations with explicit unsuccessful observation feedback and no actual or fractional data volume.
- **Missed/failed/canceled/cancelled/rejected downlink feedback plus terminal provider `contact_result` failures** — as downlink-completion, collection-latency, and required-volume demand, including provider-shaped direct mission-state rows whose `status` is a match state and whose `realized_status` carries the execution failure.
- **Actual data-rate plus duration telemetry** — as actual throughput for station-throughput and downlink-demand branch refresh.

### Event schemas

- `strategy_branch.v1` / nested `campaign_strategy.v3` event schemas type the provider result, realized status, source activity identity arrays, missed downlink identity, contact-count, downlink-volume, and latency evidence fields.

## Objectives and gap derivation

- Supported objectives: priority-commitment, target-coverage, distinct target-observation, multi-observation target-revisit, and objective-scoped multi-gap collection-latency objectives. Campaign `target_commitment` rows are single-observation commitments and share canonical `target_observation` semantics; they do not become target revisits.
- Collection-latency objective aliases are consistent across standalone refresh, V3 mission objectives, objective-satisfaction report replay, and objective-gap summaries: `collection_latency`, `collection_downlink_latency`, `data_latency`, `downlink_latency`, `max_collection_latency`, `collection_latency_limit`, `delivery_latency`, `delivery_latency_limit`, `max_delivery_latency`, and `required_delivery_latency` all drive the canonical branch-local `collection_latency` decision path.
- Downlink-completion gap additions by contact count or required data volume, including collection-latency data-volume gaps plus branch-comparison objective-satisfaction evidence inside the required latency window.

### Downlink demand and lineage

- Branch-generated refresh now turns downlink-completion gap `required_downlink_mb` into branch-local `downlink_demand_mb` feedback before generating access candidates, so refreshed downlinks carry requirement, shortfall, score evidence, and exact `downlink_demand_sources` lineage from the originating branch event instead of remaining generic contacts.
- This includes resource-projection pressure rows with station identity and required/planned volume evidence preserved from matching flow rows when supplied, and report-level provenance trust boundaries inherited onto derived pressure events when rows do not repeat them.
- Direct candidate refresh also annotates matching observation candidates with collection-latency objective IDs/types, collection/product/payload/instrument identity, `max_latency_s`, `required_downlink_mb`, and objective score evidence so the collection source is traceable before the derived downlink.

### Multiple scoped objectives

- Multiple scoped downlink-completion objectives can derive independent downlink-constrained branches.
- Multiple independent downlink-completion objective-satisfaction ratios are aggregated per objective instead of reporting only the first objective's status, so branch-comparison rows distinguish one satisfied scoped objective from all scoped objectives being satisfied.
- An objective that declares both required contacts and required downlink data volume must satisfy both before its ratio reaches full completion; derived branch risk reasons preserve both contact-count and data-volume shortfalls when both dimensions are unmet.
- Multiple independent gap events for the same station accumulate their required downlink demand rather than letting the last event overwrite earlier demand.
- Explicit branch downlink-gap events that omit their own required downlink volume inherit aggregate mission-state downlink volume demand instead of only the first objective's demand.

### Revisit/coverage aliases

- Objective-satisfaction, objective-tradeoff, and score-term target refresh now understand revisit and coverage count aliases such as `required_revisits`, `planned_revisits`, `missing_revisit_count`, and `coverage_shortfall_count`.
- Plus revisit/coverage and missed-observation target identity aliases such as
  `missing_revisit_targets`, `required_revisit_target_ids`,
  `missing_coverage_targets`, `missed_observation_target_ids`, and
  `selected_coverage_target_ids`.
- So branch-local urgent-target staging preserves the requested revisit/coverage target and quantity instead of degrading those rows to a one-observation placeholder or dropping the target identity.

### Scoped standalone objectives

- Standalone refresh downlink-completion and collection-latency objectives scoped by nested `station` / `ground_station` identity objects, `spacecraft_id`, `satellite_id`, or `scenario_id` now apply only to matching generated downlink candidates even when multiple spacecraft share the same station.
- V3 objective-satisfaction/objective-tradeoff pressure replay now carries nested source-observation/source-activity station, scenario, and planned data-volume evidence plus plural collection, product, payload, and instrument selector lists, including nested `collections`, `products`/`data_products`, `payloads`, and `instruments` object lists, into derived downlink-gap and collection-latency branches.
  - Staged downlink additions retain the triggering selectors plus plural objective IDs in their feasibility context and approval / selected-recommendation handoff rows instead of requiring those routing fields at the report-row top level.
- The same pressure replay also derives urgent-target branches from nested source observation/activity target and scenario evidence for coverage and target-gap rows.

## Prior-plan and provider-shaped activity canonicalization

- V2/V3 prior-plan activity rows accept top-level `activity_type` aliases before provider inference.
- Provider-shaped station/time contacts are canonicalized into downlink/station/time activity fields before repair and branch objective scoring so selected provider contacts count toward downlink completion, collection latency, branch risks, and resource/feedback factors.
- Validated urgent-target staging from branch-generated candidate windows and semantic candidate-diff reasons for same-ID field changes and semantically similar replacement opportunities now influence V2 replacement selection and remain visible on V3 strategic additions, recommendation explanations, and operator-review approval rows.

## Catalog generation and duplicate-ID handling

- Branch-local target and ground-station catalog generation ignores duplicate IDs within the same source rather than selecting one coordinate, priority, or station geometry arbitrarily.
- Branch-derived refresh treats mission-state `ground_stations` as the canonical geometry source ahead of same-ID `ground_network` calendar entries.
- Direct candidate-refresh inputs likewise prefer provider-normalized `station_calendar_provider.v1` rows over same-ID raw `ground_network` rows before branch-local station-state selection.
- The same provider precedence applies to mission-state and accepted-planning-state station-calendar provider fallbacks so duplicate branch-local direct calendar rows do not create false ambiguous station state.

## Candidate-refresh freshness and resource filtering

- Candidate-refresh freshness policy now checks snapshot age, horizon alignment, and accepted-state quality level, emits concrete unknown reasons when freshness cannot be fully evaluated.
- Resource filtering can apply fuel, power, storage, downlink, and externally supplied thermal margin thresholds.

## Candidate-refresh ID and ordering invariants

- Candidate refresh now canonicalizes source event-result and per-result event ordering before assigning refreshed window and candidate activity IDs, matching the V1 campaign planner's generated-ID invariant so provider/source list order does not change semantic window identity.
- It carries nested deterministic contact allocation semantics over its refreshed contact candidates, excludes deferred, blocked, and policy-blocked allocation rows from final contact opportunities, plus a deterministic candidate-limit budget report over the post-filter set with non-negative input/kept/dropped counts, an explicit no-limit `max_candidate_activities` equal to the post-filter input count, and executable validation that input count equals kept plus dropped.
- Duplicate target IDs in a refresh request no longer influence refreshed observation scoring by arbitrary target-row selection.
- Duplicate overlapping ground-station state rows likewise no longer drive arbitrary refreshed downlink capacity or reservation metadata selection, and same-severity unavailable or reserved ambiguity is now carried into refreshed contact-filter/allocation rows without selecting one calendar entry or one reservation.
- Outage/maintenance station state now outranks reserved overlaps while preserving reservation IDs, owners, and statuses on suppressed refresh contacts and allocation rows.

## Standalone candidate refresh

- **Station-throughput feedback** — consumed as a deterministic capacity factor for generated downlink candidates.
- Accumulates multiple matching explicit downlink-completion objective data-volume requirements for the same station before scoring generated downlink candidates.
- Now adds explicit operational-feedback downlink demand to matching objective demand instead of treating feedback as a fallback that can hide objective volume, while branch-derived refresh avoids applying the same operational feedback twice when V3 already materialized it into `ground_network` capacity.
- Standalone candidate refresh now also consumes target-observation (including the `target_commitment` alias), target-revisit, target-coverage, priority-commitment, and urgent-target objectives, including nested `target` objects and target-object lists, as deterministic observation-candidate score and context evidence:
  - including required-observation counts and objective IDs in both the candidate row and activity context;
  - urgent/priority objective priorities can raise the generated observation `target_priority` with objective-source evidence instead of remaining detached from target-value scoring.

### Allocation ordering and policy

- Candidate-refresh allocation now runs after resource filtering so a resource-suppressed contact cannot defer an otherwise eligible contact, while contact-filter blocked rows are still carried into the allocation report for review.
- Candidate-refresh allocation also passes `contact_allocation_policy` through to the embedded deterministic allocation report, including `default_required_capacity_fraction` for reduced-capacity packing, so branch-local refreshed contacts can share reduced station capacity under the same planning-grade pack ledger used by standalone allocation.
- **Behavioral caveat** — it still does not reserve provider time, mutate schedules, or run an optimizer search.

## Combined branch generation

- Combined branch generation is deterministic and opt-in.
- Combined branch events now carry canonical string `source_branch_id` / sorted `source_branch_ids` lineage so joint-case review can trace each combined event back to the individual derived branch that produced it, while malformed non-string lineage entries are ignored after value normalization.
- Branch-comparison aggregation filters event types and lineage IDs to sortable strings before reporting.

## Branch-event normalization

- **Trust boundaries** — branch event trust-boundary values are promoted from valid top-level or provenance strings and malformed direct values are dropped before declared/missing counts are emitted.
- **Station identity** — station identity aliases are canonicalized to string `ground_station_id` fields before branch repair, contact routing, and risk rows consume them.
- **Scalar routing IDs** — scalar branch-event routing IDs such as event, scenario, activity, target, and source-activity IDs are emitted only when they normalize to non-empty strings; provider-calendar and station reservation IDs follow the same branch-event stable-ID normalization.
- **List-shaped routing selectors** — source-activity, target, allowed-scenario, provider-calendar entry, reservation, direction, owner, status, and source-lineage lists are de-duplicated after string-only normalization while preserving declared order.
- **Timing aliases** — branch event timing aliases are parsed from numeric `start_s` / `end_s` and `actual_start_s` / `actual_end_s` inputs and emitted through the canonical `*_at_s` fields, with inverted intervals collapsed to a zero-duration event at the normalized start boundary.

### Numeric factor parsing

- Branch-event station-throughput plus contact, command, observation, and maneuver success factors parse numeric strings only when they are clean unit-interval values; out-of-range numeric values are preserved as invalid branch-event evidence instead of being clamped, while malformed values are dropped.
- Branch-event target-priority plus required-downlink demand scalars and feedback confidence/sample weights parse numeric strings only when they are zero or positive; negative values are preserved as invalid branch-event evidence and warnings instead of being floored into candidate scoring, while malformed values are dropped.

### Scalar feedback damping

- Branch-authored scalar feedback applies bounded confidence damping to branch-local refresh and scoring while preserving the declared raw scalar, weight, and weight-source fields on the reviewable branch event.
- The applied feedback-adjustment block, branch-comparison row, and selected recommendation explanation also carry the contributing `feedback_weight_sources`.

## Resource-margin and availability inference

- Branch-authored resource-margin pressure events infer their resource field from clean numeric-string `storage_capacity_margin`, `downlink_capacity_margin`, `battery_soc`, or `battery_state_of_charge` aliases.
- Derived power-constrained branches consume the same normalized resource-summary margin path as fuel, thermal, storage, and downlink pressure, so JSON-style numeric-string power margins are not ignored.
- Derived payload and antenna constrained branches likewise normalize resource-summary boolean aliases and JSON-style boolean strings before deriving branch-local unavailability evidence.
- Branch-comparison availability scoring recognizes the same aliases on top-level and nested mission resource maps, including direct spacecraft availability when no separate degraded or mode field is present, while resource-summary rows that only carry unrelated margins no longer mask spacecraft-state availability evidence.

### Degraded-spacecraft and availability scoring

- Degraded-spacecraft derivation and baseline spacecraft-availability scoring normalize `degraded?` / spacecraft availability aliases, payload/antenna status aliases, and provider-style availability status words before producing branch-local degradation evidence.
- Baseline branch-comparison resource scoring consumes the same normalized spacecraft-state antenna availability instead of defaulting antenna health to available.
- Branch-authored degraded events preserve explicit spacecraft-unavailable aliases as resource-overlay evidence.
- Branch-authored resource-availability events parse JSON-style `available` booleans and operational status words before generating branch-local resource overlays.
- Derived downlink-constrained branches preserve every low downlink and storage resource-summary row as branch-local resource pressure evidence while still using the lowest margins for deterministic branch-level scoring.

## Numeric-string acceptance across inputs

- Request-level operational-feedback factor/demand maps, resource-margin override maps, maneuver execution-uncertainty scalars/vectors, target priority overrides, target-row encoded observation-success factors, objective required counts/data-volume/latency/priority fields, scoring-policy weights, freshness-policy timing thresholds, branch-generation feedback and priority thresholds, generated urgent-placeholder booleans, current epoch, and remaining-horizon timing likewise accept clean numeric strings before branch-local candidate and freshness derivation.
- Candidate refresh now falls back to `mission_state.remaining_horizon` when the request omits a top-level `remaining_horizon`, while preserving top-level request precedence, so branch-local mission-state snapshots can bound regenerated candidates and freshness reports without duplicating horizon fields.
- Mission-state downlink-completion / collection-latency objectives normalize clean numeric-string required contacts, downlink volume, latency limits, and objective window bounds before deriving refresh branches.

### Mission-state and accepted-planning-state precedence

- Candidate refresh also advertises and verifies mission-state spacecraft-identity precedence and current-epoch fallback plus accepted-planning-state spacecraft, target, ground-network, resource-summary, current-epoch, remaining-horizon, station-calendar interval, and provider-list fallbacks.
- So refresh requests can inherit durable planning-state target value, freshness timing, bounded refresh timing, resource availability, and reservation/outage overlays when the top-level request and mission-state bundle omit live rows.

### More numeric-string normalization paths

- Branch-local planned/source downlink activity timing aliases, throughput values, station-capacity fractions, and selected activity scores normalize from clean numeric strings before objective-window matching, volume scoring, strategic branch scoring, and reduced-capacity score adjustment.
  - Numeric-string branch-local candidate activity scores, planning-horizon durations, candidate-limit counts, candidate-refresh minimum-duration constraints, and branch-refresh output cadences are also normalized before candidate ordering, replacement selection, timeline ranking, and default objective-window fallback.
- Campaign scoring-policy weights, downlink rates, rank limits, max-timeline-activity limits, and minimum-activity-duration constraints normalize from clean numeric strings before candidate generation and ranking.
- Mission-state ground-network capacity fractions and station-window timing aliases normalize from clean numeric strings before branch derivation and branch-local refresh request generation.
- Campaign target priorities, realized revisit priorities, and urgent-target branch priorities normalize from clean numeric strings before observation scoring and branch-local target insertion.
- Target specs from catalogs, objectives, and branch events normalize clean numeric-string latitude, longitude, minimum-elevation, and priority fields before branch-local refresh generation.

### Boolean-string normalization

- Explicit branch `allow_placeholder` flags normalize trimmed case-insensitive JSON-style boolean strings, including `"1"` / `"0"`, before urgent-target staging.
- Candidate-refresh `avoid_eclipse` constraints normalize trimmed case-insensitive JSON-style boolean strings before candidate filtering.
- V2 repair policy preservation and locked-change booleans normalize trimmed case-insensitive JSON-style boolean strings before timeline-protection decisions.
- V1 campaign `avoid_eclipse` constraints normalize trimmed case-insensitive JSON-style boolean strings before candidate filtering.
- V3 strategy request parsing preserves explicit `false` atom/string alias values for branch derivation flags instead of letting alternate-key `true` values re-enable derived branches.

## Branch comparison and tradeoff derivation

- Branch-comparison rows summarize branch event counts, event types, and combined source branch IDs so operator-review and import rows can inspect joint-case lineage through their preserved `source_branch_comparison` context.
- Objective-tradeoff derivation can now infer downlink-volume, contact-count, and target-observation gaps from deterministic `score_terms` evidence when report rows do not promote explicit top-level gap fields, with nested score-term map keys normalized for case/whitespace/hyphen variants.
- Standalone score-term report and operator-review score-term rows can also become branch-local downlink-completion or urgent-target refresh branches when they carry explicit station or target routing evidence.

### Score-term and provider-shaped routing aliases

- Target-gap score-term aliases including `target_gap_count`, `target_coverage_gap_count`, and `coverage_gap_count` are accepted alongside observation-count gap terms.
- Score-term, objective-satisfaction, objective-tradeoff, plus removed/changed timeline-diff branch derivation accepts provider-shaped singular `station` / `ground_station` and `target` / `*_target` objects as routing evidence rather than requiring every adapter to flatten those objects into `station_id` or `target_id` fields first.
- Objective-satisfaction branch derivation maps common provider pressure statuses such as `shortfall`, `below_target`, `at_risk`, `needs_replan`, and `late` from status aliases to canonical gap statuses, derives status from requirement-scoped status fields and JSON-style satisfaction booleans, and preserves `source_objective_status` on the derived evidence.

## Observation-success quality feedback

- Branch-authored observation-success feedback accepts image/product quality score aliases and terminal/degraded image-quality status aliases as the same deterministic scalar feedback path, preserving quality status/source, cloud-cover fraction, and blur score on the normalized branch event.
- This propagates through derived quality-feedback branches including status-only and cloud-cover/blur-only branches, generated branch refresh operational-feedback maps, refreshed observe candidates, strategy branch-comparison rows, and selected-recommendation review/import rows rather than introducing a separate image-product model.

## Recommendation explanations

- Selected recommendation explanations add `branch_event_summary` rows with the same event, status-transition summary, operator-review requirement, and combined-source evidence, and review/import rows flatten those event summary fields for adapter routing.

## Scope boundary

- Branch derivation is still intentionally narrow and still treats low storage as a deterministic downlink-relief planning trigger rather than a calibrated storage dynamics simulation.

## Roadmap

- **`near-term`** — broaden branch-local refresh derivation across richer objective semantics beyond the currently recognized score-term gap evidence and priority-commitment observation counts, and add calibrated feedback models beyond the current deterministic weighted scalar factors.
- **`later`** — incremental refresh, semantic candidate-set diffing across replans, opportunity confidence, richer branch-specific candidate refresh, and calibrated refresh cost controls beyond the current deterministic candidate limit.
- **`out of scope`** — making Cadence's operational state store part of this repo.

## Closing

This is the bridge from strategy over prior artifacts to real rolling mission planning. A V3 strategy recommendation is only operationally strong when its branches can reason from current state instead of only from old candidate windows.

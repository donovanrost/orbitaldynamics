# Contact Intent, Candidate Refresh Gates, and Allocation Policy

## Capabilities declaration

`ContactIntent.capabilities/0` declares:

- Supported directions.
- Source activity types, including provider `contact` rows and typed health-check rows.
- An optional `policy_decision.v1` approval boundary.
- Artifact-only limits.
- Public generation and summary facades for adapter discovery.

Executable validation checks standalone `contact_intent.v1` `model_limits` against those capabilities.

## Intent generation from activities

`ContactIntent.from_activities/2` and the public facade `OrbitalDynamics.contact_intents_from_activities/2` generate contact intents from activities.

- **Policy attachment** — When supplied an approval policy, they can attach per-intent policy decisions, approval requirements, and rule matches.
- **Uplink intents** — Treated as command-review authority boundaries.
- **Health-check intents** — Emitted as `health_check_review` authority boundaries for:
  - Typed `health_check` activities.
  - Provider-shaped `planned_contact` rows with `direction: health_check`.

`ContactIntent.summary/1`/`2` and `OrbitalDynamics.contact_intent_summary/1`/`2`
publish the validated `contact_intent_summary.v1` capacity-demand summary. The
summary derives required-capacity totals, source counts, station and direction
capacity maps, all-contact station/direction contact-ID routing, capacity-pack
station/direction contact-ID maps, ground-station IDs, and direction sets from
`contact_intent.v1` rows without provider reservation, schedule mutation, or
allocation authority. Generated summaries also carry the exact station-capacity
and required-capacity alias path assumptions from `ContactIntent.capabilities/0`,
so adapters can verify which declared capacity fields fed the demand evidence
without reopening the capability catalog. Existing
`contact_intent_summary.v1` artifacts are accepted as idempotent compact
handoff inputs when adapters already hold the summary.
Candidate-refresh contact-intent replay preserves the all-contact station map
and those direction maps as compact branch-local routing evidence, grouping
direction contact count, contact IDs, capacity-pack contact IDs, and
required-capacity fraction without reopening raw contact-intent rows. Candidate
refresh accepts direct and result-artifact-wrapped raw contact-intent rows plus
`contact_intent_summary.v1` inputs as the same artifact-only replay family,
preserving source paths, row counts, capacity-demand maps, all-contact station
and direction routing, and trust-boundary evidence without generating contacts
or allocating station time. When a compact contact-intent summary carries
embedded rows, CandidateRefresh derives those replay maps from the rows before
merging summary aggregates, so stale top-level direction/capacity maps cannot
mask row-local contact routing.

### Success evidence and confidence factors

- Carries command/contact success evidence and unit-interval feedback confidence factors from top-level activity fields or metadata into contact-intent rows and their approval-requirement context when valid.
- Out-of-range confidence is review-gated as invalid contact-intent input instead of being clamped into policy, review, or import evidence.

### Preserved activity context

Preserves, from the shared typed activity normalizer:

- Dependency/exclusivity stable-ID arrays.
- Reusable activity context.
- Timeline-integrity evidence.

Issue counts are exported and validated as non-negative integers.

## Downlink intent inference

- Infers downlink contact intents from provider-shaped station/time rows that omit explicit type and direction, including rows that carry nested `station` or `ground_station` identity objects instead of flat station IDs.
- Preserves nested `spacecraft` / `satellite` identity as top-level `spacecraft_id` through approval context, operator-review rows, and Cadence-import rows.

## Parsing and malformed-input handling

- **Parsed values** — Parses clean numeric-string timing aliases, estimated throughput, station calendar overlap counts, reservation-overlap counts, and command/contact confidence factors before contact-intent inference and schema validation.
- **Malformed activity inputs** — Preserves malformed contact/command/uplink/tracking activity inputs that have usable station and timing evidence as `review_invalid_activity_input` contact-intent gates with invalid-input reason and source activity evidence, including row-level contact-command review policy evidence through operator-review and Cadence-import handoffs when a policy bundle is supplied.
- **Malformed stable IDs** — Keeps malformed activity/station/scenario/source-window stable-ID values out of schema-facing contact-intent fields while preserving the raw source activity.
- **Single-row facade** — Runs the single-row `contact_intent_from_activity!` facade through the same validating timeline path as batch generation.

## Station availability and reservation evidence

- Preserves station availability, contention, reservation identity, owner/status, reservation expiration seconds, and `station_reservation_match_status` through the intent row, approval-requirement context, operator-review rows, and Cadence-import rows.
- `ContactIntent.capabilities/0` advertises the unavailable station aliases and station-availability precedence used to choose that emitted state, plus station-calendar overlap/reservation counts, reservation ID/status sets, reservation-match status row semantics, and station-reservation expiration aliases (`station_reservation_expires_at_s`, `reservation_expires_at_s`, `reservation_hold_expires_at_s`, `hold_expires_at_s`, `expires_at_s`, `expires_at`, and plural `station_calendar_reservation_expires_at_s` overlap context).

### Station-calendar trust boundary

- Preserves station-calendar trust-boundary status, trust boundary, provenance, and source calendar entry/overlap evidence through those same contact-intent handoff surfaces, flattening stable provider entry identity from nested source evidence when needed.
- Derives canonical `station_availability` from direct `availability` / `station_calendar_status` outage or maintenance aliases and nested source-calendar status evidence before contact-intent policy classification.
- Preserves the same contact/command success evidence through contact-allocation policy context, operator-review rows, and Cadence-import rows.
- Normalizes `station_id` provider rows into the exported `ground_station_id` contract.

## Approval policies and contact-intent review handoff

- Candidate-refresh contact intents use the refresh approval policy.
- V1 campaign contact intents use the campaign approval policy.

Standalone candidate-refresh, V1 campaign, V2 repair, and V3 branch-repair contact-intent approval evidence is lifted into:

- Typed `contact_intent_review` operator-review rows.
- `review_contact_intent` Cadence import rows.

So contact-review handoff rows carry policy evidence plus schema-constrained contact-intent policy gate status at both initial planning and refresh boundaries.

V2 repair also makes exact selected downlink intent pressure visible in scoring.
It reuses the V3 contact-intent identity classifier and emits one
`contact_intent_pressure_penalty` risk-weight unit per unique pressured contact
ID present in the repaired activities. Unrelated contacts, duplicate evidence,
commands and other non-downlink rows, nominal rows, and operator-review-only
approval status remain review evidence without changing repair score. This does
not reject candidates, accept policy decisions, reserve provider capacity, or
execute a Cadence action. V2 replacement ranking applies the same exact
candidate-ID pressure before selection: each pressured alternative receives one
calibrated unit and retains its sorted unique pressure statuses, while nominal,
unrelated, and review-only alternatives remain neutral.

## Candidate-diff review and import gates

Standalone candidate-refresh candidate-diff invalidations are lifted into:

- Typed `candidate_diff_review` operator-review rows.
- `review_candidate_diff` Cadence import rows.

These preserve replacement IDs, semantic-change reasons, source-window lineage, source diff evidence, and adapter-facing `candidate_diff` gate status/count fields for refresh handoff queues.

### Paired replacement rows

- Paired replacement rows also carry the replacement `source_window_lineage.v1` row and compact nested `replacement_source_window` evidence through operator-review and Cadence-import surfaces.
- Exported row schemas and executable validators check source/replacement source-window stable IDs, nested source-window identity, and lineage candidate/window matches.
- Paired replacement `new_candidates` are not duplicated.
- Unpaired semantic or ambiguous new-candidate rows and retained semantic-change rows are normalized into those same gates.

### Standalone candidate-diff artifacts

- Standalone `candidate_diff_report.v1` artifacts can be normalized directly into those same gates without requiring a full candidate-refresh wrapper.
- They preserve schema-validated `source_window_lineage` rows when present.
- They cross-check lineage candidate/window/scenario IDs against retained/new/invalidated diff rows before review/import handoff.

### Scoped context retention

- Source-window lineage and candidate-diff rows retain scoped collection/product/payload/instrument identity, source activity IDs, latency objective evidence, downlink demand quantities, and feedback trust-boundary context from refreshed downlink candidates.
- Operator-review rows, Cadence import rows, V3 replayed candidate-diff branch events, and staged replacement metadata preserve that same scoped context instead of requiring downstream queues to reopen nested diff evidence.
- Standalone `invalidated_candidate.v1` rows can be normalized directly into those same candidate-diff review/import gates.

### Candidate-diff model limits

- Embedded and standalone `candidate_diff_report.v1` artifacts emit schema-visible `model_limits` copied from `OrbitalDynamics.CandidateRefresh.capabilities/0`, and executable validation checks them against `OrbitalDynamics.CandidateRefresh.model_limits/0`.
- Embedded diff reports also carry source-window lineage directly.
- Candidate-refresh parent and subreport JSON Schema exports publish that model-limit boundary as exact string sets.

## V2 repair and V3 branch repair: candidate-diff replay

- V2 repair and V3 branch repair lift source candidate-diff reports into those same `candidate_diff_review` / `review_candidate_diff` gates, with V3 rows flattening `branch_id` for adapter routing.
- V3 branch derivation can replay operator-review or Cadence-import candidate-diff rows that name a concrete `replacement_candidate_id` into a branch-local validated replacement insertion.
- Mission-state `source_candidate_diff_report` rows feed the same branch-local path directly when they carry a concrete replacement, using the prior or refresh candidate set as the candidate source while keeping candidate-diff rows without a concrete replacement review-only.

### Replayed metadata

- Replayed branch events and staged replacement metadata preserve candidate-diff source-target metadata, target latitude/longitude/minimum-elevation fields, and target-priority value/source/objective evidence.
- The same fields flow into strategic-addition approval contexts for policy and review routing.

## Freshness review gates

Stale or unknown candidate-refresh freshness produces:

- Typed `freshness_review` operator-review rows.
- `review_refresh_freshness` Cadence import gates.

These preserve snapshot age, horizon alignment, state-quality status, stale/unknown reasons, and adapter-facing `accepted_state_freshness` gate status/count fields separately from generic warnings.

- Prior `freshness_review` and flattened `review_refresh_freshness` rows with stale or unknown status can derive branch-local refreshes from current mission-state inputs.
- Mission-state `source_freshness_report` inputs feed the same refresh-freshness pressure path while preserving the source path and trust boundary.

## Refresh-budget review gates

Refresh-budget drops produce:

- Typed `refresh_budget_review` operator-review rows.
- `review_refresh_budget` Cadence import gates.

These preserve a `candidate_budget` gate status, overflow count, kept/dropped counts, candidate IDs, selection order, and the max-candidate policy evidence.

- V2 repair and V3 branch repair lift source freshness and refresh-budget reports into those same review/import gates, with V3 rows flattening `branch_id` for adapter routing.
- Prior `refresh_budget_review` and flattened `review_refresh_budget` rows with dropped candidates can derive branch-local refreshes that relax `candidate_limit_policy.max_candidate_activities` to the reported input candidate count, letting strategy compare the budget-constrained refresh with an expanded deterministic candidate set without mutating external schedules.
- Mission-state `source_refresh_budget_report` inputs derive the same branch-local relaxed-budget comparison directly from accepted mission state.

### Standalone freshness / refresh-budget artifacts

- Standalone `freshness_report.v1` and `refresh_budget_report.v1` artifacts can be normalized directly into those same review/import gates without requiring a full candidate-refresh wrapper.
- Both report contracts expose the same candidate-refresh `model_limits` as their embedded subreports, with executable validation against `OrbitalDynamics.CandidateRefresh.model_limits/0` and exact model-limit JSON Schema export for standalone and embedded import gates.
- Freshness validation derives `status` from stale/unknown reason arrays so refresh trust gates cannot carry contradictory summaries.

## Contact-allocation policy

- Contact-allocation policy rows classify command/uplink allocation requirements as `command_review` while preserving `ContactAllocation.capabilities/0` command-contact direction metadata for catalog consumers.
- Contact-contention capabilities expose the same direction set used by command-contact priority and review routing.
- Downlink and tracking allocation rows remain contact-schedule review.
- Allocation approval requirement context carries contact identity, type, timing, and source-window evidence alongside station policy fields, including `station_reservation_match_status` so review/import rows can distinguish ID-matched or owner-matched provider reservation time from a reserved-station overlap.
- Station-calendar and contact-filter reports expose row-derived `station_reservation_match_status_counts` for adapter queue routing, with JSON Schema exports typing those summaries as non-negative integer count maps and station-calendar/contact-filter/allocation trust-boundary count maps as declared/missing count maps.

### Allocation count maps

- Contact-allocation reports export allocation-status and effective-status count maps against the canonical `ContactAllocation.capabilities/0` vocabularies while keeping allocation reasons and reservation-match summaries as open non-negative count maps validated against rows.
- The public contact-allocation summary helper derives allocation-status, effective-status, allocation-reason, capacity-pack, and reservation-match count maps from normalized rows/groups rather than copying top-level report summaries, preventing stale-but-plausible count maps from leaking into adapter routing aids.

## Reduced-capacity station packing

- Reduced-capacity station packing emits a group-level ledger with capacity, used/unused fractions, selected IDs, capacity-packed IDs, deferred IDs, pack status, and per-contact capacity requirement rows.
- Rows touched by the pack carry `capacity_pack_*` evidence through returned allocated contacts, operator-review, and Cadence-import handoffs.
- Reduced-capacity allocation normalizes explicit capacity demand from direct contact fields, nested `throughput_model`, `capacity_model`, or `activity_context` fields while preserving `required_capacity_fraction_source` for nested provider evidence.
- Packing can use a declared default required-capacity fraction for contacts without explicit demand while preserving `required_capacity_fraction_source`.
- Executable validation checks each pack group's used/unused capacity fractions and selected/packed/deferred contact ID sets against nested capacity requirement rows so stale reduced-capacity summaries fail before adapter routing.

### Capacity-pack review rows and replay

- The group ledger produces `contact_allocation_capacity_pack_review` / `review_contact_allocation_capacity_pack` rows for adapter routing.
- Prior pack review/import rows with preserved `source_contention_recommendation` evidence can replay into V3 branch-local contact-contention pressure without resubmitting the original allocation report.

## Source-derived station-pressure and reservation routing

- Contact-allocation summaries derive station-pressure routing from preserved `source_station_calendar_entry` and `source_station_calendar_overlaps` availability evidence, so source-only outage/reservation provenance remains visible even when flattened station availability fields are absent.
- Contact-intent rows consume numeric `availability` and source station-calendar `capacity_pack_capacity_fraction` evidence as station-capacity context, preserving canonical capacity fractions through operator-review and Cadence-import handoffs.
- Contact-intent rows preserve declared `required_capacity_fraction` demand from direct, throughput-model, capacity-model, and activity-context fields through operator-review and Cadence-import handoffs, and the public summary helper derives compact required-capacity totals plus per-station maps from rows instead of trusting stale aggregate fields.
- CandidateRefresh contact-intent replay preserves row-derived direction counts,
  capacity demand by direction, and contact IDs by direction alongside
  station-scoped capacity and station-feedback maps, so branch-local review
  queues can distinguish downlink, command/uplink, tracking, and health-check
  intent pressure without regenerating contacts.
- Link-capacity summaries derive station availability, station-calendar entry IDs, reservation IDs, status counts, and ground-station routing maps from preserved source station-calendar entry/overlap provenance when flattened summary row fields are absent.
- Station-reservation summaries derive compact affected-contact reservation routing from source-only reserved station-calendar entry provenance while leaving already-flattened station-calendar report rows unchanged.
- Candidate refresh preserves station-reservation hold expiration seconds as singular unambiguous `station_reservation_expires_at_s` context and plural `station_calendar_reservation_expires_at_s` overlap context from direct station-calendar rows, provider-contention groups, and preserved source-entry/overlap evidence. Contact intents also read those expiration aliases from wrapped `source_station_calendar_overlaps` rows emitted by filtering/allocation handoffs. Contact-intent capability metadata names the accepted direct aliases (`reservation_expires_at_s`, `reservation_hold_expires_at_s`, `hold_expires_at_s`, `expires_at_s`, and `expires_at`) as artifact-only handoff fields, not provider reservation authority.

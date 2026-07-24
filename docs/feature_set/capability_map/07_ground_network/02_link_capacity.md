# Link Capacity Reports

## Purpose and core report

`link_capacity_report.v1` rows capture fixed-rate downlink throughput and
selected contact capacity by ground station. They include
capacity-adjusted throughput totals derived from declared station capacity
fractions or provider percent aliases such as `capacity_percent`,
numeric `availability`, `capacity_pack_capacity_fraction`,
`station_capacity_percent`, and nested
throughput/capacity/activity context variants. Generated or replayed contacts
may also carry the same capacity evidence under `source_station_calendar_entry`
or `source_station_calendar_overlaps`; those source-calendar fractions feed the
same capacity-adjusted throughput totals when the contact itself does not
declare a station capacity.

`LinkCapacity.capabilities/0` advertises:

- The accepted station capacity fraction and capacity-percent paths used for
  capacity-adjusted throughput, plus typed fraction/percent capacity-value path
  metadata for direct contact rows and nested source station-calendar rows.
- `link_capacity_report.v1` and `link_capacity_summary.v1` now carry those
  station-capacity value paths, station unavailable aliases, station
  availability precedence, and provider direction aliases directly in
  `assumptions` as optional machine-checkable metadata. Runtime validation and
  JSON Schema export pin exact capability-derived values when present, while
  older artifacts without those optional assumption fields remain valid.
- Exact report and compact-summary `model_limits`, copied from the same
  capability metadata and pinned by executable validation plus JSON Schema export.
- Compact summary evidence for selected/actual downlink shortfall magnitudes
  plus capacity-adjusted, selected-adjusted, and unused-adjusted throughput
  row counts, totals, and station routing maps, preserved through candidate-refresh
  storage/downlink pressure replay without reopening link-capacity rows.
  Capacity-adjusted throughput evidence contributes to the composed downlink
  pressure flags even when no explicit shortfall row is present.
- Compact summary station-calendar provider and provider-entry ID routing maps
  by ground station, with top-level provider ID lists validated against those
  maps before CandidateRefresh or review queues trust compact handoffs.
- Direction counts and contact-ID maps, preserved through candidate-refresh
  link-capacity replay so branch-local review queues can route downlink,
  command/uplink, and tracking capacity evidence without reopening source rows.
- Contact stable-identity fields.
- Provider direction aliases, including short provider tokens such as `dl`,
  `down`, `downlinking`, `commands`, and `tracking_pass`.
- Provider-result map keys.

## Throughput estimation

The report supports provider-shaped nested throughput-model estimates and
duration-times-data-rate estimates when explicit throughput MB is absent.

Direct station-calendar outage evidence on contact rows is canonicalized into
zero station-capacity throughput, with provider identity and policy context
preserved.

Rows may carry optional declared downlink requirements and selected downlink
shortfall/status fields.

## Standalone facade

The same standalone `LinkCapacity` public API plus
`OrbitalDynamics.link_capacity_report/3` facade supports artifact-only
link-capacity review outside a full campaign build.

Existing `link_capacity_report.v1` artifacts are also accepted by
`LinkCapacity.report/1` and `OrbitalDynamics.link_capacity_report/1` as
idempotent handoff inputs before any raw-contact capacity rows are derived.

## Relay data-path summaries

`relay_data_path_summary.v1` publishes artifact-only relay and
store-and-forward route evidence for paths that are not direct ground contacts.
`LinkCapacity.relay_data_path_summary/2` and
`OrbitalDynamics.relay_data_path_summary/2` derive rows and top-level routing
from route inputs with source spacecraft, relay chain spacecraft, ground station,
ground downlink contact, custody status, latency/limit, risk status/reasons,
product IDs, and collection IDs.

The summary keeps row-derived route counts, relay/direct counts, custody,
latency, and risk status counts, route IDs by status and ground station, source
spacecraft IDs, relay spacecraft IDs, ground station IDs, downlink contact IDs,
and latency maxima. It does not model crosslink visibility, schedule relay
contacts, deliver custody acknowledgements, reserve provider contacts, or mutate
the mission schedule.

Generated relay route IDs are stable under source route ordering changes:
explicit `route_id`, `id`, or `data_path_id` values win when present, while
generated IDs use source spacecraft, relay chain, ground station, downlink
contact, latency/limit, product IDs, and collection IDs as the semantic
fingerprint. `LinkCapacity.capabilities/0` publishes that generated-ID scope for
adapter compatibility checks, and `Schema.identity_policy/0` exports the same
scope in checked-in JSON Schema metadata.

## Validation and review gating

Link-capacity reports preserve downlink-like candidate or selected rows that
are missing stable identity or station identity as invalid input
review/import rows. They:

- Validate malformed stable-ID contact/station/scenario/spacecraft identity
  before station grouping, with schema-facing fields sanitized or omitted.
- Include malformed non-map handoffs as `invalid_contact_shape` evidence.
- Treat throughput-bearing provider/contact rows without explicit type or
  direction as downlink-like capacity inputs, so malformed rows do not bypass
  review before throughput grouping.

Out-of-range contact/command feedback confidence and selected-contact
completion fractions are likewise review-gated as invalid link-capacity contact
inputs, instead of being clamped into aggregate capacity, policy, review, or
import evidence.

## Provider-shaped identity normalization

Provider-shaped contact rows that use:

- `station_id` instead of `ground_station_id`,
- nested `station` / `ground_station` identity objects, or
- nested `spacecraft` / `satellite` identity objects

normalize through contact filtering, standalone station-calendar overlays,
contention review, allocation, contact-intent generation, and link-capacity
summaries rather than bypassing station rules.

Station-calendar affected-contact rows preserve, through approval-policy
context, operator-review rows, and Cadence-import rows:

- Schema-safe provider result labels from scalar, list-valued, or map-valued
  provider payloads.
- Contact/command success flags.
- Feedback confidence factors.

## Approval, policy, and routing evidence

Link-capacity rows can optionally carry approval requirements, approval-rule
matches, `policy_decision.v1` evidence, and matched policy-escalation
authority/queue/role/SLA routing fields for reduced-capacity review boundaries.

They also carry, through approval context, operator-review rows, and
Cadence-import rows:

- Aggregate source contact/command success evidence.
- Schema-safe provider result labels.
- Unit-interval feedback confidence factors.
- Applied station-calendar entry IDs, provider IDs, provider-entry IDs, and
  `station_calendar_directions`.

## Reservation evidence (artifact-only, no writes)

Provider reservation IDs, reservation-hold aliases such as `On Hold`,
`reservation-held`, and `reserved-hold`, hold-expiration seconds, owners,
statuses, and match statuses also aggregate into those same link-capacity
handoffs as identity evidence, plus row-derived top-level routing summaries.
The report still avoids provider reservation writes or schedule mutation.

Station-calendar provider-contention groups likewise expose reservation
hold-expiration seconds through approval context, operator-review rows, and
Cadence-import rows as artifact-only evidence.
Station-reservation hold import-readiness summaries publish the validated
`station_reservation_hold_import_readiness_summary.v1` contract so hold counts,
review-only import classification, action/status/expiration/owner routing,
contact routing, and readiness rows stay row-derived without provider or
Cadence writes.

### Reservation report facades

`StationCalendar.reservation_report/2` and
`OrbitalDynamics.station_reservation_report/2` / `station_reservation_report/3`
provide a compact artifact-only summary over affected contact reservation
overlaps and provider-calendar contention groups as validated
`station_reservation_report.v1` artifacts. Existing
`station_reservation_report.v1` artifacts are accepted as idempotent inputs so
handoff pipelines do not need to reopen the full station-calendar report, with:

- Reservation IDs, owners, statuses, match-status counts.
- Row-derived status/count/ID validation.
- Reservation ID routing by status and match status.
- Review status derived from `station_calendar_report.v1`.

`StationCalendar.capabilities/0` advertises the reservation review
status/count, affected-contact count, provider-contention group count,
match/status count, reservation ID-set, and reservation routing ID-set row
semantics, without writing provider reservations or mutating schedules.

`StationCalendar.reservation_review_summary/1`/`2`/`3` and
`OrbitalDynamics.station_reservation_review_summary/1`/`2`/`3` publish the
validated `station_reservation_review_summary.v1` contract over row-derived
reservation counts, review status, hold-expiration status counts, reservation
ID sets by active/expired/missing/declared deadline status, and review rows,
without writing provider reservations or mutating schedules.
`StationCalendar.reservation_hold_summary/1`/`2`/`3` and
`OrbitalDynamics.station_reservation_hold_summary/1`/`2`/`3` publish the
validated `station_reservation_hold_summary.v1` contract over the hold-only
subset with owner/status routing, expiration routing, contact routing, and hold
rows under the same no-provider-write boundary.

`station_reservation_report.v1` also feeds `operator_review_package.v1`
station-reservation review rows and `cadence_import_manifest.v1` review-only
rows through public facades, so compact reservation summaries can be handed to
Cadence adapters without replaying the full station-calendar report.

## Provider counteroffers (artifact-only, no acceptance)

Station-calendar provider entries can preserve artifact-only counteroffer
evidence, including counteroffer ID, raw status, normalized negotiation state,
reason code, cost delta, lock deadline, offered start/end seconds, and
start/end/duration timing deltas. This flows through:

- Affected contacts.
- Report counters.
- Operator-review rows.
- Cadence-import rows.
- A standalone `provider_counteroffer_report.v1` derived from provider entries
  or station-calendar reports, with row-derived negotiation-state counts,
  cost-delta totals/counts, timing-delta evidence, and earliest lock-deadline
  summaries.

This happens without accepting the offer or reserving station time.

### Counteroffer review and impact facades

`StationCalendar.provider_counteroffer_review_summary/2` and
`OrbitalDynamics.provider_counteroffer_review_summary/2` expose a compact
artifact-only review-priority summary over the same report. They derive
counteroffer counts, status maps, negotiation-state maps, and lock-deadline
summaries from rows before classifying deadlines as declared, active, expired,
or missing when `now_s` is supplied, and publish counteroffer ID sets by
deadline status while preserving the no-provider-write boundary. These summaries
publish the validated `provider_counteroffer_review_summary.v1` contract so
review status, deadline routing, and review rows remain row-derived.
`StationCalendar.provider_counteroffer_import_readiness_summary/2` and
`OrbitalDynamics.provider_counteroffer_import_readiness_summary/2` publish the
validated `provider_counteroffer_import_readiness_summary.v1` contract for the
review-only import boundary, deriving readiness status, import classification,
action/status/deadline counts, and counteroffer ID routing from rows without
provider or Cadence writes.

`StationCalendar.provider_counteroffer_plan_impact_summary/2` and
`OrbitalDynamics.provider_counteroffer_plan_impact_summary/2` expose
artifact-only timing-shift and cost-delta impact rows for the same
counteroffers. They derive impact counts and cost totals from rows and include
counteroffer ID sets for timing shifts, cost deltas, and lock-deadline status
routing, with the same timing deltas preserved through standalone
provider-counteroffer report rows. These summaries publish the validated
`provider_counteroffer_plan_impact_summary.v1` contract without accepting offers
or mutating schedules.

### Counteroffer capability advertisement

`StationCalendar.capabilities/0` advertises:

- The public station-calendar, reservation-summary, and counteroffer facades.
- Provider unavailable and reservation-hold alias sets.
- The normalized provider direction alias map used by `direction` /
  `directions` / `station_calendar_directions`.
- The provider-result map keys used for affected-contact result labels.
- The `provider_counteroffer_review` and `review_provider_counteroffer`
  handoff contracts so callers can discover this artifact-only boundary before
  producing review rows.
- The provider capacity fraction and capacity-percent aliases plus typed
  capacity `unit`/`path` metadata used to derive reduced-capacity station
  evidence.
- The provider counteroffer source-field aliases normalized into review
  evidence.
- The provider-counteroffer lock-deadline statuses (`missing`, `expired`,
  `active`, `declared`), import statuses
  (`review_required_before_import`, `not_applicable`), import-readiness
  statuses/classes, and plan-impact statuses used by review, import-readiness,
  and plan-impact summaries.

## Contact allocation summaries

`ContactAllocation.summary/1` / `/3` and
`OrbitalDynamics.contact_allocation_summary/1` / `/3` expose compact
allocated, returned-allocated, deferred, blocked, policy-blocked,
invalid-input, status-blocked, resource-blocked, reduced-capacity-packed, and
reduced-capacity-deferred contact ID sets so review/import queues can route
allocation work without walking every allocation row. They also expose:

- Resource-blocked contact counts and contact ID sets by blocking dimension and
  spacecraft for resource-pressure triage.
- Station-pressure contact ID sets and count maps by ground station,
  station-calendar availability, precedence availability, precedence rank,
  reservation match status, reservation status, and reservation owner.
- Reservation ID sets by match status, status, and owner, plus reservation
  hold-expiration second values preserved from allocation rows.

Summary ID sets for invalid input, status-blocked, resource-blocked, and
reservation routing are derived from normalized rows rather than copied from
stale top-level report lists, and affected-contact station-calendar
trust-boundary counts use the same row-derived evidence.

Reduced-capacity packed/deferred contact ID sets also derive from row
`capacity_pack_status` rather than stale pack-group ID lists, and
required-capacity source counts plus contact ID sets derive from row
`required_capacity_fraction_source` values, so adapters can distinguish
contact-declared demand from default reduced-capacity policy without walking
every row.

Summaries canonicalize provider-shaped station availability, station-calendar
status, overlap-availability, and reservation-match tokens before building
those routing maps, including direct station-availability summaries over
existing report rows, and preserve station-calendar precedence rank/availability
evidence with station-pressure contact ID and count routing by precedence
availability and rank.

`ContactAllocation.station_pressure_summary/1` / `/3` and
`OrbitalDynamics.contact_allocation_station_pressure_summary/1` / `/3` expose
that station-pressure subset as a focused artifact-only preflight for review
queues that only need station, availability, precedence-availability, and
precedence-rank routing. The helper derives its maps from allocation rows and
does not reserve provider time, mutate schedules, or grant operator authority.

`contact_allocation_report.v1` also exports and executable-validates the
reduced-capacity pack status count map, row-derived capacity-pack status count
map, capacity-pack contact IDs by status, required-capacity source count and
contact-ID maps, and station-pressure contact ID maps by ground station,
availability, precedence availability, precedence rank, and station-calendar
status, so those routing
summaries remain visible in checked-in artifacts and schema bundles.

## Actual throughput derivation

Contact-contention groups and resolution recommendations aggregate
reservation-hold expiration seconds as artifact-only context, plus actual
throughput from provider actual-data-volume or actual data-rate plus duration
evidence.

Rate-duration derivation details are preserved in
`actual_data_rate_throughput_derivation` / plural
`actual_data_rate_throughput_derivations` fields across timeline-feedback,
contact-allocation, contact-contention, and link-capacity review/import
handoffs, with nested derivation/unit/rate/duration/throughput fields covered
by exported JSON Schema and executable validation. These rows carry applied
`station_calendar_directions` into approval context, review rows, and
Cadence-import rows.

## Command-window capability advertisement

`CommandWindow.capabilities/0` advertises the unavailable station aliases,
station-availability precedence, direct/source station-calendar capacity
fraction/percent paths, typed capacity `unit`/`path` metadata, provider
direction aliases, provider-result map keys, and reservation expiration context
used to derive station-calendar review gates from direct and nested calendar
evidence. Capability metadata names the accepted direct aliases
(`station_reservation_expires_at_s`, `reservation_expires_at_s`,
`reservation_hold_expires_at_s`, `hold_expires_at_s`, `expires_at_s`,
`expires_at`) and plural `station_calendar_reservation_expires_at_s` overlap
context. Link-capacity summaries preserve the same expiration aliases from
wrapped `source_station_calendar_overlaps` rows emitted by upstream filtering,
intent, or allocation handoffs. Command-window rows preserve singular and plural
reservation expiration seconds through approval context, operator-review rows,
and Cadence-import rows. `capacity_pack_capacity_fraction` evidence feeds the
same direct, source-activity, and source station-calendar capacity path metadata
as canonical `capacity_fraction`.

## Unit-interval and integrity enforcement

The station-calendar, contact-filter, resource-filter, link-capacity,
contact-contention, contact-allocation, contact-intent, and command-window
contracts enforce the same unit interval on source contact/command confidence
factors before those rows feed policy/review/import surfaces. Policy
action-rule thresholds for contact, command, observation, and maneuver success
factors use the same unit-interval bounds.

Contact-intent review/import pressure contributes to the dedicated V3
`contact_intent_pressure_penalty` score term instead of blending into generic
`risk_penalty`, while preserving the same total one-risk-weight penalty per
contact-intent pressure risk.
Contact-contention and contention-resolution pressures likewise contribute to
`contact_contention_pressure_penalty`, keeping contention review pressure
separate from unrelated generic risk without changing total branch penalty
weight.
Contact-filter downlink suppression pressure contributes to
`contact_filter_pressure_penalty`, keeping filtered contact-window pressure
separate from unrelated generic risk while preserving the same total branch
penalty weight.
Resource-availability pressure contributes to
`resource_availability_pressure_penalty`, keeping payload, antenna, spacecraft,
and generic resource unavailability separate from both generic risk and
storage/downlink margin pressure.
Fuel, power, and thermal margin pressure contributes to
`resource_margin_pressure_penalty`, while storage and downlink margin pressure
remain in `storage_downlink_pressure_penalty`.
Projected battery-depletion pressure contributes to
`battery_depletion_pressure_penalty`, separate from storage/downlink projection
pressure and generic risk.

`policy_decision.v1` rule-match evidence preserves those source confidence
factors with the same bounds. Communication rule-match counters for concurrent
contacts, contact-pair overlaps, and ambiguous station-calendar entries, plus
top-level policy approval/risk counts, export and validate as non-negative
integers.

Station provider/calendar, link-capacity, allocation, contact-filter, policy,
review, and import contracts also enforce unit-interval station capacity
fractions before reduced-capacity evidence reaches planning and handoff rows.

Executable station-calendar validation cross-checks affected-row counts,
duplicate-row counts, affected duration, trust-boundary maps, and
overlap/ambiguity/reservation count-list pairs against emitted rows before
downstream allocation and filtering consume that provider evidence.

## Selected-throughput totals

Selected-throughput totals require a selected contact ID to match exactly one
candidate row, with duplicate candidate IDs and unmatched selected IDs excluded
from selected capacity. Unmatched selected IDs are surfaced as review-gated
operator-review and Cadence import rows instead of remaining top-level report
metadata only.

Terminal or approval-rejected downlinks are audited with zero available or
selected capacity. Declared capacity fractions are validated against the same
unit interval used by contact filtering before station capacity totals are
emitted. Top-level and station-row ignored-reason counts are derived from the
ignored candidate or selected rows, where approval rejection takes precedence
over terminal status.

## Realized downlink reconciliation

Selected realized downlink rows that carry `actual_throughput_mb`,
provider-style actual-downlink, actual-data-volume, delivered/received aliases,
or actual data-rate plus duration now reconcile limited actual delivery totals,
actual throughput contact IDs, and actual downlink shortfall/status fields into
link-capacity, operator-review, and Cadence-import rows.
Candidate-refresh storage/downlink pressure replay also preserves
actual-throughput row counts and pressure flags from link-capacity provenance
so actual delivery evidence remains visible even when no stable contact ID is
available. Actual-throughput evidence contributes to the composed downlink and
storage/downlink pressure flags without being classified as shortfall pressure.

Link-capacity pressure recommendation rows preserve canonical risk type;
ground-station, source-activity, and source-window identity; required/planned
contact and downlink demand; and start/end bounds across operator review, direct
Cadence import, and review-derived import copies. Executable validation rejects
missing or stale derived routing, demand, or timing while paired legacy omission
remains compatible; the evidence remains descriptive and cannot grant operator
authority, reserve station time, or mutate a schedule.

`LinkCapacity.capabilities/0` advertises the accepted actual-throughput aliases
(`actual_throughput_mb`, `actual_downlink_mb`, `actual_data_volume_mb`,
`delivered_data_mb`, `received_data_mb`), the same aliases nested under
`throughput_model`, actual data-rate aliases (`actual_data_rate_mb_s`,
`actual_downlink_rate_mb_s`, `delivered_rate_mb_s`, `received_rate_mb_s`,
`actual_data_rate_mbps`, `actual_downlink_rate_mbps`, `delivered_rate_mbps`,
and `received_rate_mbps`), and actual duration aliases (`actual_duration_s`,
`actual_contact_duration_s`) used for artifact-only rate-duration derivation.

Selected realized downlinks with `completed_fraction` or completion aliases
carry average actual completion-fraction evidence through the same surfaces,
without treating realized feedback as a full provider reconciliation model.
Capability metadata also advertises direct and nested `throughput_model`
completion-fraction aliases (`completed_fraction`, `completion_fraction`, and
`contact_completion_fraction`).

Unmatched or duplicate-candidate actual-throughput or completion-fraction rows
are preserved as unresolved review/import evidence, including station-scoped row
fields for affected ground stations, instead of being silently counted or
discarded.

## Executable validation of link-capacity summaries

Executable validation cross-checks, against row and invalid-input evidence so
adapters can trust routing summaries without recomputing every station row:

- Top-level link-capacity contact counts, selected counts, ignored IDs and
  reason-count maps including ignored selected-contact reason maps.
- Throughput totals.
- Schema-validated exact `model_limits` copied from
  `LinkCapacity.capabilities/0` for both reports and generated summaries.
- Capability row semantics for both ignored-contact reason-count maps.
- JSON Schema exports for top-level and station-row contact counters plus
  ignored-reason count maps as non-negative integer summaries.
- Actual-throughput/completion contact evidence.
- Duplicate/ambiguous selected IDs, invalid-input IDs, and count/list
  cardinality pairs.

## Triage summary facade

`LinkCapacity.summary/1` / `/3` and `OrbitalDynamics.link_capacity_summary/1` /
`/3` expose a compact artifact-only `link_capacity_summary.v1` triage view over
the same report, including:

- Selected, ignored, required-downlink, actual-throughput/completion,
  unresolved actual evidence, invalid-input, and shortfall station ID sets.
- Station-keyed contact ID sets.
- Station-calendar entry/provider IDs.
- Reservation IDs/statuses.
- Actual completion contact IDs grouped by ground station.
- Station IDs grouped by availability, reservation-match status, reservation
  status, or reservation owner.

This works without rerunning link analysis, canonicalizing maintenance/outage
availability to unavailable before reduced-capacity grouping so adapter
summaries preserve the stronger blocking evidence.

The summary contract validates row-derived counts, throughput/shortfall totals,
station-keyed ID maps, unresolved actual-throughput/completion evidence, station
calendar/reservation ID sets, and the artifact-only assumptions boundary.
Existing `link_capacity_summary.v1` artifacts are accepted as idempotent compact
handoff inputs when adapters already hold the summary.
CandidateRefresh accepts direct, accepted-state, mission-state, and
result-artifact-wrapped `link_capacity_summary.v1` handoffs as compact
link-capacity source provenance, preserving the summary contract, source
identity, station count, selected/actual shortfall evidence,
capacity-adjusted throughput totals and station maps, selected/actual contact
IDs, paths, and trust boundaries without rerunning link analysis or mutating
contact allocation. When a compact summary carries embedded rows,
CandidateRefresh derives those station, throughput, contact-ID, source-window,
and direction-routing maps from the rows before merging top-level summary
aggregates, so stale summary fields cannot hide row-local downlink pressure.
CandidateRefresh also accepts direct, accepted-state, mission-state, and
result-artifact-wrapped `relay_data_path_summary.v1` handoffs in the same
link-capacity provenance family, preserving route counts, relay/direct route
IDs, source and relay spacecraft IDs, ground downlink contact IDs,
custody/latency/risk status maps, path-qualified provenance, and artifact-only
no-scheduling/no-allocation boundaries without rerunning relay analysis. When
embedded rows are present, CandidateRefresh derives those route counts, route
ID maps, spacecraft IDs, and ground downlink contact IDs from the rows before
trusting top-level relay summary aggregates.

`LinkCapacity.capabilities/0` advertises the triage summary's station/contact,
selected/ignored, required-downlink, actual-throughput/completion, invalid-input,
and invalid-policy station count row semantics, plus those unavailable station
aliases and the station-availability precedence map used by summary routing. It
derives ignored-contact, ignored-selected-contact, reservation-match count maps,
and scalar contact/selected/required/actual evidence counters from station rows
or evidence lists, so stale top-level link-capacity report summaries cannot leak
into the triage view.

## Declared-demand model

Per-contact `required_downlink_mb` values drive declared demand when no
explicit policy requirement overrides them. Those source contact IDs plus
aggregate/exact `downlink_completion_source` / `downlink_completion_sources`
lineage flow through link-capacity rows, approval context, review/import rows,
and nested throughput/activity-context handoffs.

`LinkCapacity.capabilities/0` advertises the policy, per-contact demand, and
completion-source paths used by that declared-demand model.

Station-scoped policy downlink requirements with no matching candidate contacts
still emit station-level shortfall rows for review/import queues. Malformed
station-scoped policy keys are preserved as invalid requirement metadata plus
review/import actions, instead of synthesizing schema-invalid station rows or
inflating throughput demand.

Invalid link-capacity candidate and selected-input rows can carry
approval-policy evidence through operator-review and Cadence-import handoffs.

## Schema export model limits

Standalone JSON Schema exports for contact, command, station-calendar,
link-capacity, allocation, contention, and resource filter/projection reports
constrain top-level `model_limits` as exact capability string sets for
non-Elixir import gates. Resource-filter scalar candidate counters export and
validate as non-negative integers.

The same exact export pattern covers policy, operator-review, maneuver-review,
execution, Monte Carlo, benchmark, timeline, Cadence import, and planner
explanation report model-limit arrays.

## Campaign and repair integration

V1 campaign and V2 repair downlink-completion objectives drive
selected-capacity shortfall review when no explicit policy requirement
overrides them, including aggregate required downlink volume across multiple
explicit objectives.

V1 campaign plus V2 repair embedded link-capacity reports pass their approval
policy into that row-level classification.

V3 branch repair link-capacity rows preserve low `actual_completion_fraction`
and realized-throughput `actual_downlink_completion_ratio` evidence through
ground-network policy review, operator-review packaging, and Cadence import
handoff. Link-capacity-derived branch pressure now contributes to the dedicated
V3 `link_capacity_pressure_penalty` score term instead of blending into generic
`risk_penalty`, while preserving the same total one-risk-weight penalty per
link-capacity shortfall risk.

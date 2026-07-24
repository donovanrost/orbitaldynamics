# Contact Allocation

## Facades and core behavior

`ContactAllocation` and the public `OrbitalDynamics.allocate_contacts/3` plus `OrbitalDynamics.contact_allocation_report/3` facades compose:

- declared ground-network rows, or singular/list-valued `station_calendar_provider.v1` inputs, with
- station- and spacecraft-scoped contention recommendations

into schema-validated **allocated**, **deferred**, and **blocked** contact rows.

Existing `contact_allocation_report.v1` artifacts are also accepted by
`ContactAllocation.report/1` and `OrbitalDynamics.contact_allocation_report/1`
as idempotent handoff inputs before any raw-contact allocation is derived.

This is done **without provider reservation, approval, or schedule mutation**.

When embedded in `campaign_plan.v1`, the allocation report is declared as an
optional direct nested contract and runs the same executable validator used by
the standalone facade, including required fields, typed counters and maps,
allocation rows, reduced-capacity pack groups, nested station/filter/contention
reports, model limits, and supported optional summary consistency checks. V1
context additionally pins `campaign_plan.candidate_activities` as its source.

## Accepted input shapes

Allocation accepts both typed contact rows and provider-shaped rows:

- typed contact rows, including:
  - health-check station windows
  - direction-only station windows
- provider-shaped station/time contact rows **without explicit type or direction**

It honors nested identity objects before contention grouping:

- `station` / `ground_station`
- `spacecraft` / `satellite`
- provider `source_window`

Top-level `activity_type` aliases from exported timeline-style rows are honored before provider downlink inference across:

- contact filtering
- allocation
- contention
- contact-intent generation
- link-capacity summaries

## Provider direction aliases

Allocation accepts the same short provider direction aliases as the station-calendar / link-capacity boundaries, before station-calendar direction filtering and command-review routing:

- `dl`
- `down`
- `downlinking`
- `commands`
- `sband_command`
- `s_band_command`
- `tracking_pass`

The contact-filter, contact-contention, contact-intent, and command-window reports use the **same alias set** before station-window suppression, contention grouping, intent creation, and command-window review handoff. Command-window capability metadata also names the reservation-expiration aliases accepted before review/import handoff, keeping those fields artifact-only rather than provider reservation authority.

## Allocation triage summary

`ContactAllocation.summary/1`/`3` and `OrbitalDynamics.contact_allocation_summary/1`/`3` expose the validated `contact_allocation_summary.v1` compact **artifact-only** allocation triage summary over `contact_allocation_report.v1`, including:

- returned allocated IDs
- review contact IDs/rows, preserved through candidate-refresh contact-allocation
  replay for branch-local operator-review queues; compact review identity is a
  sorted unique stable-ID list and remains usable without a fabricated count
- declared allocation-status counts and effective-status counts, preserved
  separately through candidate-refresh contact-allocation replay, with
  string-equivalent keys merged and only positive integer entries retained so
  zero-only compact maps cannot create branch-local pressure; each map is
  independently bounded by positive allocation row count while preserving
  partial reason evidence and custom status/reason keys
- allocation-reason contact-ID maps, preserved through candidate-refresh
  contact-allocation replay for branch-local triage queues, with canonical
  stable reason/ID routing and local ID cardinality bounded by any positive
  reason count while route-only reasons remain usable
- row-derived scalar allocation/contact counters, including declared
  blocked/deferred counts for candidate-refresh replay; blocked/deferred row
  counts remain mutually exclusive, nonnegative, and jointly bounded by
  positive allocation row identity before they can create branch-local pressure
- allocated, returned-allocated, deferred, blocked, and policy-blocked contact
  IDs plus allocated/returned/policy-blocked counts and station maps, preserved
  through candidate-refresh contact-allocation replay for branch-local
  allocation queues; top-level identity lists are canonical sorted unique stable
  IDs, and paired occurrence counts cannot be smaller than de-duplicated
  identity cardinality while count-only or identity-only evidence remains
  usable. Station maps canonicalize stable stations/IDs, contribute to the
  top-level identity union, and require counts to cover routed memberships
- row-derived direction counts/contact-ID maps plus station-pressure and
  reservation-conflict direction and direction/ground-station routing,
  preserved through candidate-refresh contact-allocation replay for branch-local
  direction-scoped review queues. Station-pressure nested routes roll into
  canonical direction/station parents and aggregate direction routing, with
  positive local counts bounding identity cardinality; availability,
  precedence, rank, and status review dimensions use the same local correlation.
  Reservation-conflict direct and routed stable IDs form one canonical top-level
  identity union and exact unique-contact count, with direction aliases and
  nested station keys normalized before replay
  and match-status/direction count maps retained only when positive canonical
  local counts bound their routed contact and reservation identities. Nested
  station routes roll up into the aggregate direction-routing review identity
- invalid-input, duplicate-contact-ID, status-blocked, and resource-blocked
  counts/contact IDs plus resource-blocked maps by blocking dimension and
  spacecraft, preserved through candidate-refresh contact-allocation replay for
  branch-local blocked-input queues; invalid-input, status-blocked, and
  resource-blocked top-level IDs remain canonical identity-first evidence whose
  paired occurrence counts cannot be smaller than unique ID cardinality.
  Resource dimension counts and dimension/spacecraft routes are canonicalized;
  counted dimension routes stay within local counts, route-only evidence remains
  usable, and routed IDs contribute to top-level resource-blocked identity.
- capacity-pack contact counts, required-capacity demand totals,
  selected/deferred demand totals, per-station/per-status demand maps, and
  all-contact plus selected/deferred station contact-ID routing, plus contact IDs and counts by capacity-pack
  requirement source, contact IDs by capacity-pack status, and reduced-capacity
  packed/deferred ID sets, plus reduced-capacity pack group counts/statuses/IDs
  preserved through candidate-refresh contact-allocation replay
- station-pressure contact IDs by ground station, direction/ground-station,
  availability, precedence availability, precedence rank, station-calendar
  status, and review
  requirement, preserved through candidate-refresh contact-allocation replay for
  branch-local station queues; station-pressure review IDs are canonical stable
  identity and define their exact unique-contact count when present, while a
  scalar-only summary retains its fallback count
- reservation IDs
- trust-boundary counts
- explicit no-provider-reservation / no-authority assumptions

The schema derives scalar counts, routing maps, review rows, capacity-pack
groups, station-pressure fields, reservation-expiration fields, and
resource-blocked fields from the included allocation rows without reserving
provider time, mutating schedules, or granting operator authority. Its
assumptions carry the capability-declared allocation statuses, effective
statuses, station availability aliases/precedence, capacity-pack statuses,
reservation match/expiration statuses, required-capacity source/path metadata,
and provider direction aliases, with schema validation rejecting stale present
values while preserving older artifacts that omit the optional metadata. Existing
compact allocation summaries are also accepted as idempotent handoff inputs
when adapters already hold `contact_allocation_summary.v1`,
`contact_allocation_station_pressure_summary.v1`,
`contact_allocation_reservation_conflict_summary.v1`,
`contact_allocation_provider_reservation_request_summary.v1`, or
`contact_allocation_capacity_pack_summary.v1` artifacts.

`ContactAllocation.reservation_conflict_summary/1`/`2`/`3` and `OrbitalDynamics.contact_allocation_reservation_conflict_summary/1`/`2`/`3` expose the validated `contact_allocation_reservation_conflict_summary.v1` reservation-conflict routing contract from allocation report rows, including conflict/review contact IDs, reservation match-status conflict maps, reservation status/owner/ID maps, expiration status maps, conflict/review row subsets, and the same no-provider-reservation / no-schedule-mutation boundary. The schema derives counts, routing maps, reservation IDs, expiration classification, and row subsets from included `contact_allocation_report.v1` rows. Its assumptions carry the capability-declared station-reservation match statuses, reservation-conflict match statuses, reservation-expiration statuses, and provider direction aliases, with schema validation rejecting stale present values while preserving older artifacts that omit the optional metadata. Candidate-refresh contact-allocation replay preserves reservation-conflict contact IDs and reservation IDs by match status, plus general station-reservation match-status counts and contact/reservation ID maps by match status, status/owner counts, expiration status/deadline routing, review-time active/expired classification, and contact/reservation ID maps by status/owner/expiration status, for branch-local reservation queues.
Operator-review packages and Cadence-import manifests also lift
reservation-conflict contact-ID maps by direction and by direction/ground
station from embedded summaries, so station-reservation review adapters can
route reserved-overlap work without reopening candidate-refresh provenance.
The contact-allocation capability metadata advertises this reservation-conflict path as a `station_reservation_review` / `review_station_reservation` handoff so unresolved reserved-station overlaps are not confused with ordinary contact-allocation or provider-reservation request work.

`ContactAllocation.provider_reservation_request_summary/1`/`2`/`3` and `OrbitalDynamics.contact_allocation_provider_reservation_request_summary/1`/`2`/`3` expose the validated `contact_allocation_provider_reservation_request_summary.v1` provider-reservation request summary over allocated reservation rows. Identity- or owner-matched allocated rows are classified as request-ready, allocated reservation overlaps are kept in review, and non-candidate rows are counted separately; the schema derives the summary's counts, request status, contact-ID routing, reservation-ID routing, request rows, and review rows from the included allocation rows. Request-ready, review-required, and no-request groups also expose row-derived contact IDs by direction and ground station for adapter queues that split provider work by antenna and contact direction. Its assumptions carry the capability-declared provider-reservation request statuses, station-reservation match statuses, and provider direction aliases, with schema validation rejecting stale present values while preserving older artifacts that omit the optional metadata. The helper does not reserve provider time, mutate schedules, or grant operator authority.
Candidate-refresh replay preserves the compact summary's full allocation rows when present, so no-request counts, contact IDs, direction maps, and direction/ground-station maps are row-derived instead of trusting stale top-level no-request aggregates. Derived operator-review packages and Cadence import manifests preserve the summary's `contact_allocation_provider_reservation_request_summary.v1` source contract, candidate/request/review/no-request counts, request-status counts, request/review/no-request contact IDs, request/review contact IDs by station and match status, request/review/no-request contact IDs by direction and ground station, and request/review reservation IDs by match status at their own top-level adapter boundary. Lifted request-status count maps accept only the capability-declared `clear`, `request_ready`, and `review_required` keys in executable validation and generated schemas; their values remain embedded-summary observation counts. When matching aggregate contact counts are supplied, positive `request_ready` observations require a positive request count and positive `review_required` observations require a positive review count; missing legacy counts remain optional. Reservation-ID routes retain both scalar `station_reservation_id` and list-valued `station_calendar_reservation_ids` evidence, including multiple or shared reservations per contact. Request contact and reservation routes accept only `matched` and `owner_matched`, the statuses eligible for provider request readiness; review routes retain the full capability-declared `matched`, `owner_matched`, and `overlap` vocabulary because matched rows without reservation identity remain review work. Reservation-ID routes are merged as sorted unique arrays per match status, including explicit empty routes; when both contact and reservation route maps are present, adapters align their match-status keys and both handoffs reject noncanonical arrays or mismatched route vocabularies without treating reservation identity as contact-count evidence.
Campaign-planner provider-pressure branches retain the selected contact row's scalar and list-valued reservation IDs, owners, and statuses through the event, risk indicator, branch metadata, and canonical branch-comparison reservation context. This selected-row evidence preservation does not reserve provider time, mutate schedules, or turn aggregate reservation routes into planner effects.
The same provider-pressure handoff retains selected-row station-calendar entry, provider, and provider-entry identities so branch comparison and review adapters can trace the reservation evidence to its calendar source without consulting aggregate maps.
Provider-pressure events, risks, and branch provenance also retain the selected contact's source-window identity and normalized start/end times. Branch comparison derives canonical source-window IDs plus the earliest event start and latest event end. It also correlates source-window-bearing events into sorted per-ID bounds, using each ID's earliest start and latest end while preserving partial timing evidence and ignoring unrelated timed events. Operator-review and Cadence-import comparison rows preserve both the aggregate and correlated versioned context.
When a source comparison or strategy recommendation/tradeoff review supplies that window context, executable handoff validation requires the derived operator-review or Cadence-import row to preserve each supplied field and rejects stale copies. Per-ID bounds require stable IDs, canonical order, at least one endpoint, valid endpoint order, and membership in the branch source-window IDs. Earliest-start and latest-end bounds remain independently optional for partial event evidence; legacy source and derived rows remain valid when both omit the optional fields.
Multi-window handoffs retain the complete sorted list across comparison, recommendation, and tradeoff source copies; list equality is exact, so an omitted row or stale per-ID endpoint cannot silently cross the review/import boundary.
The selected-recommendation path preserves the same context from its branch-event explanation through operator review, selected Cadence import, and review-derived Cadence import. Source-window IDs without usable timing remain visible in the ID list without receiving fabricated bound rows.
The same rows expose row-derived total source-window, bounded-window, and untimed-window counts plus canonical untimed source-window IDs. Start-only/end-only bounds additionally produce canonical partially timed source-window IDs and a count, so review queues can locate incomplete endpoints without reopening every bound. A row-derived timing-coverage status classifies the evidence as `complete`, `partial`, or `untimed`: `complete` requires both numeric endpoints for every source window, while any nonzero start-only/end-only or missing-window evidence remains `partial`. Executable validation fixes those summaries and status to the authoritative ID/bounds lists, so timing coverage cannot drift independently in review or import artifacts. When a source copy supplies any coverage field, operator-review and Cadence rows must preserve it; legacy source/derived pairs may continue omitting the optional fields together.
Selected provider-review rows also retain their reservation expiration deadline and classification. Candidate-source provider-review replay reattaches the same classification only when the review contact appears in an exact expiration-status route. Request-ready candidate replay additionally emits request-scope operator-review pressure only when the exact request contact is routed as `expired` or `missing`; it preserves the source `request_ready` classification instead of rewriting the summary. Those classifications therefore contribute the existing reservation-expiration pressure penalty beside the provider-request penalty, while request-ready `active`, unrelated, absent, and aggregate-only expiration evidence remain neutral and cannot independently create planner effects. Branch comparison, operator-review tradeoff, and Cadence comparison rows preserve the resulting canonical expiration-status list at their top-level adapter boundary. The selected-recommendation path preserves the same list from the recommended branch-event explanation through operator review, direct selected Cadence import, and review-derived Cadence import. Provider-request, station-conflict, and station-hold recommendation risk drivers additionally preserve each source risk's scalar expiration classification, while recommendation review and both Cadence paths expose family-scoped canonical unique classification lists alongside their existing reservation context. Station-calendar recommendation rows expose their canonical risk classifications, derivation reasons, required operator actions, feedback-source and feedback-scope provenance, and source trust boundary; stable ground-station, entry, provider, provider-entry, overlap-entry, and ambiguous-entry IDs; numeric start/end bounds and bounded capacity fractions; calendar-scoped and selected reservation IDs; direction; station and overlap availability; calendar and contention status; general and reservation overlap counts; ambiguity flag and count; calendar-scoped owner/status plus selected reservation owner/status/match; calendar trust-boundary status; provider-calendar contention-group ID/status, entry IDs, provider IDs, provider-entry IDs, availabilities, directions, reservation IDs, owners, reservation statuses, trust-boundary statuses, and five-field overlap pairs; expiration classification; and numeric reservation-deadline lists under the same exact-copy validation. When a source recommendation, comparison, or review supplies one of those lists, executable validation requires an exact derived copy; legacy source/derived pairs may omit the optional field together.
Provider-reservation-request recommendation rows separately preserve canonical contact, source-activity, ground-station, and station-reservation identity; direction; reservation owner/status/match; request status and row scope; required operator action; explicit authority assumptions; expiration classification; feedback source/scope; and source trust boundary across the same four copies. Executable validation rejects missing or stale derived request routing, state, review/authority context, or provenance while paired legacy omission remains compatible; the evidence does not submit a request, accept provider time, create or modify a reservation, grant operator authority, or execute a schedule.
Capacity-pack risk recommendation rows preserve canonical contact, source-activity, ground-station, and reduced-capacity pack-group identity; capacity-pack status and bounded capacity, used, unused, and required fractions; required-fraction source; derivation reasons; feedback source/scope; and source trust boundary across the same four copies. Executable validation rejects missing or stale derived capacity-pack risk routing, quantitative state, or provenance while paired legacy omission remains compatible; the evidence remains descriptive and cannot reserve station time or mutate a schedule.
Contact-intent recommendation rows likewise preserve their canonical risk type; candidate contact, source-activity, ground-station, source-window, timeline, policy-bundle, station-calendar entry, calendar-provider, provider-entry, and station-reservation IDs; timing bounds; required/planned contact-count and downlink-volume demand; and approval, required-action, Cadence-import, invalid-import flag/reason, activity-validity flag/reason, gate-status, policy-classification, station-availability, contention-status, calendar-direction, calendar-status, calendar trust-boundary, reservation owner/status, reservation-match, feedback-source/scope, source trust-boundary, and derivation-reason context from source risks through operator review, direct selected Cadence import, and review-derived Cadence import. Executable validation rejects missing or stale derived classification, identity, timing, demand, or review/import/policy/station/provenance context while legacy source/derived pairs may omit the optional context together. Invalid activity evidence retains its source reason; a valid activity input retains `false` without fabricating one.
Contact-allocation recommendation rows preserve their canonical risk type; contact, scenario, spacecraft, ground-station, source-activity, source-window, policy-bundle, station-reservation, and station-calendar entry identity; required/planned contact and downlink demand; demand-source, completion-source, feedback-source/scope, source trust-boundary, and derivation-reason provenance; start/end bounds; and realized, contact-result, allocation, effective-allocation, review, approval, policy-classification, reservation-owner/status, reservation-match, calendar-entry status, and calendar-direction state with the allocation reason across the same four handoff copies. Executable validation rejects missing or stale derived routing, demand, timing, outcome/review, policy, reservation, calendar, or provenance context while legacy source/derived pairs may omit the optional context together. Policy, reservation, calendar, and provenance evidence is descriptive and grants no execution, reservation, completion-credit, or calendar-mutation authority.
Station-reservation-conflict recommendation rows separately preserve canonical contact, source-activity, ground-station, and reservation identity plus owner, reservation status, match status, expiration deadline/classification, derivation reasons, feedback source/scope, and source trust boundary across the same four copies. Executable validation rejects missing or stale derived conflict routing, state/deadline, or provenance context while paired legacy omission remains compatible; this evidence cannot accept, modify, or create a reservation.
Station-reservation-hold recommendation rows separately preserve canonical hold and contact identities; hold-ID routing by import status, required import action, direction, and direction/ground station; contact-ID routing by import status, expiration status, direction, and direction/ground station; nonnegative counts by import status and required import action; import status; import-readiness summary model, source, source artifact type, status, classification, and nonnegative hold count; the complete typed source-summary evidence; expiration classification; feedback source/scope and source trust boundary; and explicit artifact-only import, no-provider-write, no-Cadence-write, and no-reservation-acceptance boundaries across the same four copies. Executable validation rejects missing or stale derived hold identity/routing, count, summary identity/state/evidence, provenance, or execution boundary while paired legacy omission remains compatible; the evidence performs no provider or Cadence write and cannot accept a reservation or grant operator authority.

`ContactAllocation.capacity_pack_summary/1`/`2`/`3` and `OrbitalDynamics.contact_allocation_capacity_pack_summary/1`/`2`/`3` expose the validated `contact_allocation_capacity_pack_summary.v1` reduced-capacity pack routing contract without reopening the full allocation report. The summary derives capacity-pack contact counts, selected/deferred demand totals, per-status/per-station/per-direction demand maps, all-contact plus selected/deferred station and direction contact-ID routing, requirement-source routing, pack group IDs/statuses, review rows, and explicit no-provider-reservation / no-schedule-mutation assumptions from included `contact_allocation_report.v1` rows and reduced-capacity pack groups. Its assumptions also carry the capability-declared capacity-pack status vocabulary, reduced-capacity pack-group status vocabulary, required-capacity source values, and required/default required-capacity value paths, with schema validation rejecting stale present values while preserving older artifacts that omit the optional metadata. Candidate-refresh contact-allocation and storage/downlink replay summaries preserve the same selected/deferred station and direction demand, per-status demand maps, all-contact plus selected/deferred station and direction contact-ID maps, capacity-pack contact counts, contact IDs by status, requirement-source counts/contact IDs, packed/deferred ID sets, reduced-capacity pack group counts/status/ID routing, and allocation-review contact IDs for branch-local review queues.
Operator-review packages and Cadence-import manifests also lift those
capacity-pack all/selected/deferred contact-ID maps by direction from embedded
contact-allocation summaries, so adapter queues can split reduced-capacity pack
work by contact direction without reopening the summary artifact. Dedicated
`contact_allocation_capacity_pack_review` rows also expose the same
all/selected/deferred direction routing and required-capacity fraction maps from
their embedded reduced-capacity pack source evidence, with schema validation
rejecting stale row/source mismatches.

`ContactAllocation.station_pressure_summary/1`/`2`/`3` and `OrbitalDynamics.contact_allocation_station_pressure_summary/1`/`2`/`3` expose the validated `contact_allocation_station_pressure_summary.v1` station-pressure routing contract without reopening the full allocation report. The schema derives input/station-pressure/review counts, contact IDs, station/availability/precedence/status routing maps, count maps, review rows, and explicit no-provider-reservation / no-schedule-mutation assumptions from included `contact_allocation_report.v1` rows. Its assumptions carry the capability-declared unavailable aliases, blocking availability values, availability precedence, and provider direction aliases used by station-pressure routing, with schema validation rejecting stale present values while preserving older artifacts that omit the optional metadata.
Operator-review packages and Cadence-import manifests also lift branch-local
`station_pressure_contact_ids_by_direction` replay maps when embedded
contact-allocation summaries provide them, so direction-scoped station-pressure
queues do not need to reopen candidate-refresh provenance.

## Capability advertisement

`ContactAllocation.capabilities/0` advertises:

- those public facades
- operator-review / Cadence-import handoff artifact contracts
- allocation review/import action names
- contact stable-identity fields for catalog discovery

## Invalid-input handling and integrity

Allocation blocks contact-like rows missing required identity, station, or timing fields as **reviewable invalid input rows** instead of silently dropping them before filtering/contention.

- Malformed stable-ID contact / station / source-window / scenario and station-overlay identity fields are routed to invalid-input review rows, with schema-facing fields sanitized or omitted while preserving the original `source_contact_candidate`.
- Malformed non-map contact handoff rows are preserved as `invalid_contact_shape` evidence instead of crashing the allocation report.

Allocation blocks **duplicate contact IDs** before station filtering or contention allocation, so reused contact identifiers cannot apply one resolution decision to multiple candidates or collide exported row IDs.

## Station overlay blocking and reservation matching

Allocation blocks any contact direction when the station overlay is unavailable, maintenance, or zero-capacity, while preserving reserved / reduced-capacity rows as reviewable boundaries.

- Downlinks that match the provider reservation identity are allocated for review, while unmatched contacts in that reserved interval are blocked.

Allocation rows normalize direct reservation aliases into canonical station-reservation ID, owner, status, and match-status fields, so reservation-priority contention selections keep ownership evidence after allocation.

- Provider-normalized station-calendar rows preserve top-level `station_calendar_provider_id` and `station_calendar_provider_entry_id` through allocation, approval requirements, operator review, and Cadence import rows.
- Provider-counteroffer suppression rows from ContactFilter preserve offer ID / status / negotiation / reason / cost / lock-deadline / offered-timing evidence plus start/end/duration timing deltas before ContactAllocation carries them through blocked allocation rows, approval context, operator review, and Cadence import — **without accepting counteroffers or mutating schedules**. Unknown-only negotiation-state metadata is kept nested instead of flattened into review/import counteroffer fields.
- Allocation also flattens provider-counteroffer handoff fields from
  `source_station_calendar_overlaps`, including wrapped overlap rows emitted by
  contact filtering, so overlap-only provider calendar evidence reaches
  allocation review/import rows without reopening nested station-calendar
  payloads.
- Nested provider source-window maps preserve canonical source-window identity and payload evidence through allocation approval context plus review/import rows.

## Contention priority evidence handoff

Allocation review/import rows flatten:

- selected/deferred contention priority evidence
- custom priority-field numeric evidence coverage
- override count/ID metadata

so Cadence import gates can route priority-aware allocation decisions without unpacking nested contention recommendations.

The same priority evidence is available to allocation approval-policy action rules, including selectors for:

- `priority_fields_without_numeric_evidence_count_min`
- `priority_fields_without_numeric_evidence`

`ContactAllocation` capability metadata advertises the inherited contention selection rules, tie-breakers, default priority fields, and priority-override aliases, alongside the `contention_priority_evidence_handoff` and `contention_priority_field_evidence_handoff` capabilities.
`ContactContention.capabilities/0` also advertises the required-capacity
fraction/percent paths used to derive contention resolution capacity-pack demand
summaries before allocation consumes those recommendations. Its resolution
summary also routes required-capacity demand by selected/deferred status plus
source counts and contact IDs by source, matching the allocation summary
boundary for review queues.
`contact_contention_report.v1` now carries optional capability-derived
assumptions for contact type/direction vocabularies, station availability
aliases and precedence, station/source/required capacity value paths,
reservation-priority vocabularies, resolution priority metadata, provider
aliases/result keys, contact identity fields, and command-contact directions;
present stale values are rejected while older reports can omit the additive
fields.

## Reduced-capacity blocking and packing

Reduced-capacity station overlays can block contacts that declare a `required_capacity_fraction` above the available station capacity, preserving the required/available fractions through allocation, operator-review, Cadence import, and schema validation.

Contact-allocation `capacity_pack_capacity_fraction` evidence feeds the same
typed station-capacity path as canonical `capacity_fraction`, including
source station-calendar entry/overlap evidence used before reduced-capacity
blocking or packing.
When selected activities later carry multiple station-calendar overlaps with
embedded contact-allocation evidence, resource projection now chooses blocking
allocation evidence before allocated evidence, so deferred or policy-blocked
overlaps cannot accidentally relieve storage or downlink pressure because of
provider overlap ordering.

**Percent aliases** — provider percent aliases are normalized into the same fractions before reduced-capacity blocking and packing:

- `capacity_percent`
- `station_capacity_percent`
- `required_capacity_percent`
- `required_station_capacity_percent`
- nested throughput/capacity/activity context percentage variants, including non-ambiguous source station-calendar entry/overlap capacity evidence

`ContactAllocation.capabilities/0` advertises:

- the station capacity, source station-calendar capacity, and required-capacity fraction/percent paths
- typed fraction/percent capacity-value metadata
- the default required-capacity option paths and typed default required-capacity `unit`/`path` metadata
- required-capacity source values used by row-derived report/summary routing
- capacity-pack row statuses (`selected_by_contention_resolution`, `selected_by_reduced_station_capacity_pack`, `deferred_by_reduced_station_capacity_pack`) and reduced-capacity pack-group statuses (`all_fit`, `capacity_limited`)
- reservation match statuses (`matched`, `owner_matched`, `overlap`), reservation-conflict match statuses (`overlap`), and reservation-expiration statuses (`missing`, `declared`, `active`, `expired`) used by reservation-conflict summaries
- provider direction aliases
- provider-result map keys used by those allocation decisions
- provider-counteroffer handoff fields
  (`provider_counteroffer_id`, `provider_counteroffer_status`,
  `provider_counteroffer_negotiation_state`,
  `provider_counteroffer_reason_code`, `provider_counteroffer_cost_delta`,
  `provider_counteroffer_lock_deadline_s`,
  `provider_counteroffer_starts_at_s`, and
  `provider_counteroffer_ends_at_s`, plus
  `provider_counteroffer_start_delta_s`,
  `provider_counteroffer_end_delta_s`, and
  `provider_counteroffer_duration_delta_s`) preserved through allocation
  review and import

**Out-of-range inputs** — out-of-range declared capacity requirements or contact-supplied station-capacity annotations are preserved as invalid allocation inputs instead of being clamped into planning demand.

**Packing** — allocation can pack additional deferred overlapping same-station contacts when their explicit capacity requirements fit within the declared reduced capacity.

- Callers can declare a planning-grade `default_required_capacity_fraction` for reduced-capacity packing when contacts lack explicit per-contact capacity demand, with rows and pack ledgers preserving the default source.
- The pack ledger applies that default before claiming any selected contact as allocated, so a contention-selected contact whose default demand exceeds reduced station capacity is **deferred** instead of over-crediting unavailable capacity.

**V3 branch replay** — V3 branch replay preserves deferred-contact `capacity_requirement_rows` evidence as branch-local downlink pressure capacity-demand fields, plus branch-comparison capacity demand summaries that flow through operator-review and Cadence-import strategy tradeoff rows and selected strategy-recommendation review/import rows — **without modeling provider reservation or link budgets**.

## Status-blocked and rejected contacts

Terminal, status-policy-blocked, or source approval-rejected / policy-blocked contacts are audited as blocked rows with status-blocked counts/IDs and contact-effect reasons before station filtering or contention allocation, so they remain reviewable without being returned as usable allocated contacts.

- Source approval rejection takes precedence over terminal/status state in the blocked reason.
- Source terminal or approval-rejected reasons remain stable even when station-calendar overlays add unavailable/maintenance context for audit.
- Policy-blocked contacts without a more specific station block still report the policy block as the allocation reason.

**Realized evidence** — status-blocked realized contacts preserve, through allocation rows, approval context, operator-review rows, and Cadence-import rows:

- supplied `actual_throughput_mb`, or provider-style actual-downlink / delivered / received aliases
- actual data-rate plus duration
- `completed_fraction`, or provider-style completion aliases

Out-of-range completion fractions and contact/command success factors are preserved as invalid allocation inputs instead of being clamped into valid-looking feedback.

`ContactAllocation.capabilities/0` advertises the unavailable station aliases, blocking availability values, and station-availability precedence map that drive allocation blocking and station-pressure routing.

## Downlink completion evidence

Allocation rows preserve, through approval context, operator-review rows, and Cadence-import rows:

- required/candidate downlink completion evidence
- selected shortfall
- requirement status
- aggregate source
- exact `downlink_completion_sources` lineage from the contact row or nested throughput/activity context

The allocation row schema and executable validation type the realized throughput/completion, downlink-completion, and contact/command success evidence directly, **without treating allocation as realized-provider reconciliation**.

`ContactAllocation.capabilities/0` declares those preservation guarantees as row semantics while retaining only `no_full_realized_contact_reconciliation` as the realized-provider model limit, with executable `contact_allocation_report.v1` validation checking saved `model_limits` against those capabilities.

When a declared station calendar overlaps a terminal contact, the blocked row also preserves reservation, availability, trust, and source-calendar context for audit without returning it as an allocatable contact, with `model_limits` still declaring no full realized-contact reconciliation.

## Resource-summary ingress

Allocation can optionally consume externally supplied `resource_summary.v1` rows through the existing `ResourceFilter` boundary before station allocation, preserving nested `resource_filter_report.v1` evidence plus blocked allocation rows for suppressions in these dimensions:

- antenna
- spacecraft
- power
- fuel
- storage
- payload
- externally supplied thermal-margin
- downlink-margin

This includes row-derived resource-blocked contact counts/IDs and source resource-suppression context with battery state, spacecraft mode, and explicit resource-summary activity-type suppression/incompatibility lists.

- Contact-allocation summaries expose the same resource-blocked pressure grouped by blocking dimension and spacecraft, through allocation rows, executable row validation, operator-review, and Cadence-import handoff.
- Allocated contacts retain the source resource summary and resource evidence that made them eligible.

This is done **without adding a subsystem simulator or resource roll-forward model**.

## Policy decisions

Allocation can optionally run reviewable rows through `policy_decision.v1`, so blocked, deferred, reserved, unavailable, and reduced-capacity contact-allocation boundaries carry approval-rule matches and escalation evidence for review.

- The returned allocated-contact list excludes rows whose policy decision is `blocked_by_policy`, even when the report preserves their allocation status for audit.
- The same policy evidence is preserved on nested:
  - `station_calendar_report.v1` affected-contact rows
  - `contact_filter_report.v1` suppressed-contact rows
  - `contact_contention_report.v1` / `contact_contention_resolution_report.v1` conflict and recommendation rows inside allocation reports

V3 branch-local refresh preserves `station_calendar_provider.v1` provider IDs, provider entry IDs, direction scope, status, and trust-boundary provenance through generated ground-network events into suppressed `contact_filter_report.v1` rows and branch-comparison evidence.

## Station-calendar evidence on rows

Allocation rows preserve, in both rows and approval context:

- station-calendar entry IDs
- overlap counts
- overlap availabilities
- provider-calendar directions
- provenance object shape
- same-priority ambiguity markers
- reservation overlap IDs/owners/statuses

The allocation row schema and executable validator type the provider-calendar direction, provenance, and ambiguous-entry ID/count evidence directly, so Cadence-facing review/import rows do not need to reopen the nested station calendar report.

V1 campaign plus candidate-refresh embedded allocation reports pass their approval policy into those row-level decisions.

## Station-calendar trust-boundary counters

`station_calendar_report.v1` emits:

- `calendar_entry_trust_boundary_status_counts` over every declared calendar entry
- `station_calendar_trust_boundary_status_counts` over affected contacts
- row-derived `station_reservation_match_status_counts`

so provider trust provenance and reservation-match routing remain auditable even when a calendar input has no overlapping contacts.

Station-calendar affected rows classify provider trust-boundary provenance as `declared` or `missing`, while preserving that status plus singular reservation owner, status, and `station_reservation_match_status` through approval context, operator-review rows, and Cadence-import rows.

## Executable validation

Executable validation enforces non-negative scalar report counters and provider-contention group entry counts, and cross-checks the following before downstream review/import handoff:

- affected-contact totals
- calendar-entry trust-boundary totals
- row-derived trust-boundary counts
- duplicate affected-contact row totals
- reservation-overlap counts against reservation ID lists

## V3 derived branch generation

V3 derived branch generation treats mission-state ground-network entries as follows:

- `availability: reserved` entries the same as `status: reserved`
- `availability: maintenance` entries as station outages

It preserves reservation IDs, owner, and status into branch-local candidate refresh and contact suppression, instead of dropping station-calendar state before repair.

## Availability-only maintenance semantics

Contact filtering plus station-calendar provider and raw ground-network normalization apply the same availability-only maintenance semantics, and numeric `availability` values are accepted as capacity-fraction aliases, so reduced/zero capacity cannot bypass suppression, allocation, review, or link-capacity annotations. Contact filtering also treats `capacity_pack_capacity_fraction` as typed station-capacity evidence before zero-capacity suppression.

**Standalone contact filtering** canonicalizes provider-shaped availability, status, contention, reservation-match, overlap-availability, and nested source station-calendar status tokens — including outage/down/offline aliases — before suppression and review handoff.

- Direct contact candidates with station-calendar outage evidence are suppressed even when no separate ground-network interval is supplied.
- Nested source-calendar outage evidence outranks lower-severity flattened status fields.

`ContactFilter.capabilities/0` advertises those unavailable aliases and the station-availability precedence map used for suppression routing. `contact_filter_report.v1` now carries optional capability-derived assumptions for unavailable aliases, availability precedence, station/contact capacity value paths, suppressed directions/reasons, and provider direction aliases; present stale values are rejected while older reports can omit them.

- Direct/provider station-calendar counteroffer evidence produces **review-only** contact-filter suppression rows **without accepting the offer, reserving provider time, or mutating the schedule**.

## Canonicalization across boundaries

**Contact allocation** applies the same canonicalization to direct contact station-calendar status evidence before allocation, policy decisions, and review/import rows, so direct handoffs cannot bypass unavailable-station blocking with provider outage aliases.

- This includes direct rows that carry only `availability` or `station_calendar_status` instead of a flattened `station_availability`.
- Nested source-calendar outage evidence outranks lower-severity direct status fields.

**Contact contention** derives group/recommendation `station_availability` and `station_calendar_status` from the same direct and nested source-calendar status evidence before policy classification, and canonicalizes direct reservation status and match-status evidence before priority-aware resolution, so owned reserved station time is not missed because of provider casing or whitespace/hyphen variants.

- `ContactContention.capabilities/0` advertises those unavailable aliases, station-availability precedence, and reservation-priority status vocabularies.

**Approval-policy matching** canonicalizes station availability, contention, reservation status, reservation match status, and provider-calendar reservation status values on both rules and requirement context before classification, so the same provider-shaped status variants cannot bypass ground-network policy review.

**Operator-review station-calendar package inputs** canonicalize direct affected-contact status fields and nested source station-calendar entry/overlap evidence before deriving review actions, and Cadence import manifests built directly from station-calendar reports inherit the same canonical review-package boundary.

**Candidate-refresh** ground-network availability, status, and contention tokens are canonicalized for case, whitespace, and hyphen differences before generated downlink throughput/scoring, outage, reservation, and reduced-capacity filtering; provider-shaped nested station identity is canonicalized; and clean station-window timing aliases are parsed before refresh chooses the applicable station-calendar state.

**V3 recommendation policy** treats a positive canonical `unavailable` station-suppression count from contact-filter replay as `contact_filter_blocked` under the default approval policy. Reserved, reduced-capacity, and unknown provider-status replay remains an operator-review boundary rather than a hard recommendation block.

**File-backed campaign and candidate-refresh manifests** preserve the same `availability` semantics plus reservation metadata and ground-network provenance, instead of flattening availability-only station rows to available status or dropping branch-refresh calibration evidence.

## Review and import normalization

Standalone contact allocation reports normalize into:

- `operator_review_package.v1` `contact_allocation_review` rows
- `cadence_import_manifest.v1` `review_contact_allocation` rows

V1 campaign artifacts embed the same `contact_allocation_report.v1` over campaign candidate contacts, preserving allocation, suppression, and contention context for Cadence-facing review gates, with explicit `effective_allocation_status` and returned/policy-blocked allocated-contact counts so policy-blocked selections remain visible but are not counted as usable returned contacts.

Returned allocated contacts preserve, from their report row:

- effective allocation status
- review status
- selected/deferred contention context
- flattened contention priority evidence
- priority-override count/ID metadata
- approval-policy evidence

so V1/V2/V3 callers can consume the allocated list without losing operator-review requirements.

## Report counters and routing

Allocation reports carry non-negative scalar contact counters and row-derived allocation-status, effective-allocation-status, and allocation-reason count maps with executable validation and JSON Schema bounds, plus row-derived:

- station-reservation overlap counters, IDs, owners, statuses
- match-status counts
- reservation-expiration status counts plus contact/reservation ID routing,
  using declared/missing status without a clock and active/expired/missing when
  `now_s` is supplied
- trust-boundary counts
- invalid-input IDs
- status-blocked IDs
- duplicate-ID counts
- reduced-capacity pack demand totals, selected/deferred demand totals, demand
  maps by pack status and ground station, and packed/deferred contact IDs
- stale top-level reservation-list checks

so adapters can route contact queues without recounting rows.

- Allocation row `review_status` is schema/export constrained to **accepted-for-planning** or **operator-review-required** states, so import gates cannot invent readiness labels.

**Trust evidence on rows** — allocation rows carry station-calendar trust evidence, flatten provider entry IDs from nested station-calendar source evidence onto report rows and returned allocated contacts, and emit `station_calendar_trust_boundary_status_counts` plus lifted `calendar_entry_trust_boundary_status_counts`, so Cadence review/import adapters can route by stable provider entry while distinguishing declared provider state from missing-boundary station data even when the provider calendar entry does not affect an allocation row.

- Contact-allocation reports lift resource-blocked dimension counts and
  dimension/spacecraft contact-ID maps to the top-level report boundary, so
  downstream review/import adapters can route resource pressure without
  re-opening row evidence.
- Derived operator-review/import artifacts preserve the same resource-blocked
  dimension counts and dimension/spacecraft contact-ID maps at their own
  top-level adapter boundary.
- Derived operator-review/import artifacts also preserve capacity-pack demand
  totals/maps, contact IDs by pack status, all-contact plus selected/deferred
  station contact-ID maps, required-capacity source counts/contact-ID maps,
  reduced-capacity pack group counts/statuses/IDs, and packed/deferred contact
  IDs at their own top-level adapter boundary.
- Station-reservation contact IDs by match status are canonical and fix the
  corresponding match-status contact count; match-status keys without contact
  identity retain additive fallback. Reservation-ID routes remain separate
  evidence and do not define contact cardinality.
- Station-reservation contact IDs by expiration status likewise fix each routed
  expiration-status count and the dedicated declared/missing contact count when
  applicable; status keys without contact identity retain additive fallback,
  and reservation-ID routes do not define contact cardinality.
- Station-reservation contact IDs by reservation status likewise fix each
  routed status count; count-only status keys remain compatible, and
  reservation-ID routes do not define contact cardinality.
- Station-reservation contact IDs by reservation owner likewise fix each routed
  owner count; count-only owner keys remain compatible, and reservation-ID
  routes do not define contact cardinality.
- Top-level station-reservation IDs form the sorted unique union of direct and
  match/status/owner/expiration reservation-ID routes. Route-only handoffs
  synthesize top identity, while legacy artifacts may still omit that optional
  top field; supplied top and routed identity must be canonical and consistent.
- Station-reservation owner and status vocabulary lists form sorted unique
  unions of direct values plus their matching count, contact-ID, and
  reservation-ID map keys. Count/route-only handoffs synthesize the top
  vocabulary, while legacy artifacts may omit it; supplied lists must be
  complete and canonical.
- Station-reservation expiration seconds form a sorted unique list, with each
  report's detailed list taking precedence over its earliest scalar and
  scalar-only reports supplying fallback values. The handoff derives the
  earliest scalar from that list; legacy scalar-only artifacts remain valid,
  while supplied lists must be canonical and scalar-consistent.
- Capacity-pack group IDs form a canonical top-level union across direct and
  status-routed identity evidence and fix the exact group count. Each supplied
  status route likewise fixes its status count; count-only keys and top-absent
  routed legacy handoffs remain compatible.
- Capacity-pack contact IDs by status are canonical and fix the corresponding
  contact-status count; status keys without identity retain additive fallback.
- Required-capacity contact IDs by source are canonical and fix the corresponding
  source count; source keys without identity retain additive fallback.
- Provider-reservation request, review, and no-request contact identities are
  independent canonical top-level unions across their available direct and
  routed evidence. Request/review include station, direction, nested
  direction/station, and match-status routes; no-request includes direction and
  nested direction/station routes. Each fixes its exact count when identity
  evidence is supplied. Count-only and top-absent routed legacy handoffs remain
  compatible.
- Derived operator-review/import artifacts preserve station-pressure contact
  counts, canonical top-level contact IDs, and contact-ID maps by ground station,
  availability, precedence availability, and precedence rank, plus
  station-pressure review contact IDs, at their own top-level adapter boundary.
  Top-level identity is the canonical union across direct, review, grouped,
  direction, and nested direction/station evidence and fixes the exact unique
  contact count across overlapping embedded reports. Each grouped ID route
  likewise fixes its per-key count, while keys without identity evidence retain
  additive legacy fallback. Nested direction/station IDs also populate canonical
  flat direction routes. Supplied review IDs separately form a canonical union
  that fixes the exact review-contact count, with count-only legacy fallback.
- Derived operator-review/import artifacts preserve those reservation summaries,
  expiration routing maps/counters, reservation contact/reservation ID maps by
  match status, reservation status, and reserved-by owner, and the lifted count
  maps at their own top-level adapter boundary, with executable non-negative
  count-map validation.

## Cross-artifact aggregation

V1 campaign, candidate-refresh, V2 repair, and V3 strategy wrappers aggregate the same embedded contact-allocation reservation summaries and count maps across source and repaired allocation reports before review/import handoff.

**V2 repair artifacts** emit:

- `contact_allocation_report.v1` over repaired contact activities, including same-spacecraft cross-station contention over the repaired timeline; they pass repair approval policy into that allocation boundary, and lift repaired-plan allocation rows into V2 and V3 branch-repair operator-review/import surfaces.
- the same `link_capacity_report.v1` contract over repaired downlink activities.
- Supplied candidate-refresh allocation rows with an exact viable contact ID and
  reduced-capacity station evidence now contribute the shared calibrated
  station-pressure unit to V2 replacement ranking and final selected-plan
  scoring. Deferred, blocked, reserved, nominal, nonmatching, and unselected
  rows remain neutral; matching live station-calendar evidence is deduplicated
  rather than charged twice. This is a ranking/review signal, not hard
  suppression, provider reservation, or schedule mutation. Pressured replacement
  rows list the exact `campaign_repair.source_contact_allocation_report.rows`
  and/or `campaign_repair.source_station_calendar_report.affected_contacts`
  source paths that contributed; nominal rows omit the list.

**Cadence import manifests** expose row-derived `source_review_type_counts` and `source_review_action_counts` alongside import/action/status counts, so adapters can route review queues without reopening every source review row.

**V3 branch derivation** replays allocation-row `source_contact_suppression` and `source_resource_suppression` evidence from operator-review and Cadence-import contact-allocation rows as branch-local contact-filter or resource-filter pressure, while preserving the contact-allocation downlink gap branch, so a station/resource-blocked allocation handoff does not lose its underlying cause when it crosses the review/import boundary.

And `station_calendar_report.v1` rows for campaign-manifest-supplied

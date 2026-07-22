# Contact Allocation Report

`contact_allocation_report.v1` is available through
`OrbitalDynamics.Communications.ContactAllocation` and the public
`OrbitalDynamics.allocate_contacts/3` plus
`OrbitalDynamics.contact_allocation_report/3` facades. It composes declared
ground-network contact filtering and station- or spacecraft-scoped contention
resolution into
deterministic allocated, deferred, and blocked contact rows with embedded
source filter/contention reports. Allocation accepts native contact `type`
fields and direction-only station rows so Cadence-facing command, tracking,
health-check, and downlink windows do not have to invent a synthetic activity
type before review. Health-check allocation policy boundaries emit
`health_check_review` requirements rather than generic contact-schedule
requirements.
Operational timeline and contact-intent normalization now follow the same
direction-only station-window boundary for command/uplink/tracking and
health-check handoffs, while command-result rows that omit command type or
direction remain invalid review inputs.
Provider-shaped station/time contact rows without explicit `type` or
`direction` are treated as downlink-like allocation inputs, and nested
`station` / `ground_station` identity objects normalize to canonical
`ground_station_id` fields before allocation, contact-intent generation, and
link-capacity summaries. Nested provider `source_window`,
`metadata.source_window`, or `activity_context.source_window` maps likewise
derive canonical `source_window_id` and `source_window_type` evidence for
allocation rows, approval-policy context, operator-review rows, Cadence-import
rows, returned allocated contacts, and invalid-input review rows: valid rows can
be allocated or blocked by station rules, and malformed rows stay on the invalid
input review path. Contact allocation also parses clean numeric-string timing
aliases, capacity-fraction requirements, and provider percentage aliases such
as `capacity_percent`, `station_capacity_percent`, and
`required_capacity_percent` before filtering, reduced-capacity blocking, and
packing decisions; malformed numeric strings remain missing numeric evidence
and out-of-range percentages stay on the invalid/review paths.
Unavailable, maintenance, or zero-capacity station overlays block any contact
direction at allocation time; provider outage-style availability aliases such
as `outage`, `down`, and `offline` canonicalize to unavailable before
station-calendar precedence is applied. Direct contact handoffs that carry only
`availability` or `station_calendar_status` with unavailable/maintenance
semantics derive the same flattened `station_availability` before allocation
and policy classification. Nested `source_station_calendar_entry` or
`source_station_calendar_overlaps` availability/status evidence participates in
the same severity ordering, so provider outage evidence cannot be masked by a
flatter `available` value. Affected station-calendar rows expose the applied
precedence rank and availability token, so review queues can see when
unavailable or maintenance evidence beat reserved or reduced-capacity overlaps
without replaying the provider-calendar ordering. Reserved or reduced-capacity
station overlays remain reviewable allocation boundaries unless policy blocks them.
Contact-allocation rows preserve the same precedence rank and availability
token, and allocation reports plus summaries expose station-pressure contact ID
routing by ground station, availability, precedence availability, and
precedence rank so adapters can triage the applied calendar ordering without
reopening every allocation row.
Contacts that are already terminal or approval-rejected retain that source
status/approval allocation reason even when a station overlay also marks the
interval unavailable or maintenance, while the station-calendar context still
flows into allocation, operator-review, and Cadence-import rows. Policy-blocked
contacts without a more specific station block still report the policy block as
the allocation reason.
Downlink rows whose declared station reservation identity or owner matches the
provider reservation pass through contact filtering into allocation review,
while unmatched contacts in the same reserved interval are blocked. Allocation,
operator-review, and Cadence-import rows preserve
`station_reservation_match_status` so adapters can distinguish owned reserved
time from an overlap with another reservation. Contact-filter and allocation
reports also summarize those rows in
`station_reservation_match_status_counts`, so adapters can route reservation
matches and overlaps without scanning every row.
Allocation rows normalize direct reservation aliases (`reservation_id`,
`reserved_by`, `reservation_status`, and `reservation_match_status`) into the
canonical station-reservation fields, so contacts selected by reservation-aware
contention policy keep ownership evidence after allocation. Allocation
operator-review and Cadence-import rows also flatten contention priority
evidence (`selected_priority`, `selected_priority_source`, and
`deferred_contact_priorities`), custom priority-field numeric evidence coverage,
and priority-override count/ID metadata, so import gates can route
reservation-priority and other priority-aware allocation decisions without
unpacking the nested contention recommendation. The same priority evidence is included in allocation
approval-policy activity context, allowing action rules to match priority-aware
allocation decisions directly, including
`priority_fields_without_numeric_evidence_count_min` plus
`priority_field_without_numeric_evidence` /
`priority_fields_without_numeric_evidence` selectors for custom priority fields
that had no usable numeric evidence. `ContactAllocation.capabilities/0`
advertises these handoffs as `contention_priority_evidence_handoff` and
`contention_priority_field_evidence_handoff`.
Allocation rows also preserve station-calendar trust evidence from provider
overlays, including `station_calendar_entry_id`,
`station_calendar_directions`, `station_calendar_trust_boundary_status`,
`trust_boundary`, `provenance`, `source_station_calendar_entry`, and
`source_station_calendar_overlaps`;
allocation rows flatten the provider entry ID from either the canonical
`station_calendar_entry_id` field or nested source-entry `id`, and the same
flattened ID is returned on allocated contacts. The report
summarizes those rows in `station_calendar_trust_boundary_status_counts` and
row-derived `station_reservation_ids`, `station_reserved_bys`,
`station_reservation_statuses`, and `station_reservation_match_status_counts`,
so adapter queues can route owned or overlapping provider reservation windows
without reopening every allocation row. It
also lifts the nested
`station_calendar_report.calendar_entry_trust_boundary_status_counts` to
top-level `calendar_entry_trust_boundary_status_counts` so review/import queues
can route declared provider state separately from missing-boundary station data,
even when no allocation row overlaps the declared calendar entry. Operator
review packages and Cadence import manifests derived from a contact-allocation
report preserve those reservation summaries and the lifted count map at their
own top level as source-report summary evidence, and V1 campaign,
candidate-refresh, V2 repair, and V3 strategy wrappers aggregate the same
embedded contact-allocation reservation summaries and count maps across their
source and repaired allocation reports before review/import
handoff. Allocation row validation now also checks provider-calendar direction
lists, provenance object shape, and ambiguous-entry ID/count evidence directly
instead of leaving those review-driving fields as untyped extensions.
Provider-reservation request summaries route `request_ready` rows through
`review_provider_reservation_request` operator-review and Cadence-import
actions, while `review_required` overlap rows remain on the generic
`review_contact_allocation` queue. The handoff stays review-only: the summary
does not execute provider reservations, grant operator authority, or mutate the
schedule.
Allocation rows also preserve downlink-completion evidence from the contact row
or nested `throughput_model` / `activity_context`: `required_downlink_mb`,
`candidate_downlink_mb`, `downlink_completion_ratio`,
`selected_downlink_shortfall_mb`, `downlink_requirement_status`,
`downlink_completion_source`, and exact `downlink_completion_sources` lineage
flow into allocation approval context, operator-review rows, and Cadence import
rows. This keeps requirement shortfall and source-lineage evidence attached to
the contact-selection decision without turning contact allocation into a link
budget or realized-provider reconciliation model. The allocation row schema and
executable validator also type the same downlink-completion fields, realized
throughput/completion fields, and contact/command success evidence so adapter
preflight cannot silently accept malformed review-driving feedback. When
allocation derives `actual_throughput_mb` from actual data-rate plus duration,
the row, approval context, operator-review row, and Cadence import row preserve
an `actual_data_rate_throughput_derivation` object with formula, rate unit,
duration, and derived megabytes.
Reduced-capacity station packing now emits a group-level ledger with capacity,
used/unused fractions, selected IDs, capacity-packed IDs, deferred IDs, and
pack status. The ledger includes `capacity_requirement_rows` with each contact's
capacity demand, source, allocation status, and pack decision so operators can
audit the pack without recomputing demand from contact rows. Rows touched by the
pack carry `capacity_pack_*` evidence, and operator-review plus Cadence-import
rows preserve that evidence. Returned allocated contacts also retain
`capacity_pack_*` evidence, so planner handoff can explain contacts promoted by
reduced-capacity packing without reopening the report rows. The exported row
schema keeps `approval_status` optional, matching executable validation and the
reduced-capacity pack fixture where capacity-pack rows are reviewable without
policy approval evidence. The group ledger also becomes a
`contact_allocation_capacity_pack_review` /
`review_contact_allocation_capacity_pack` handoff row so adapter queues can
route reduced-capacity selections without recomputing the pack. V3 branch
derivation can replay those prior pack review/import rows through the same
contact-contention pressure path when the preserved pack row carries a
`source_contention_recommendation`, retaining deferred-contact IDs, source
contact candidates, capacity fractions, source paths, and review/import trust
boundaries. When the pack review/import row carries `capacity_requirement_rows`,
the derived branch-local downlink pressure event preserves the deferred
contact's `required_capacity_fraction` and
`required_capacity_fraction_source`, so branch refresh keeps the same declared
capacity demand that drove the original reduced-capacity pack. Branch
comparison rows summarize that replayed demand with
`capacity_pack_max_required_capacity_fraction`,
`capacity_pack_total_required_capacity_fraction`, and
`capacity_pack_required_capacity_sources`, allowing strategy review to compare
reduced-capacity pressure without reopening each branch event. Operator-review
packages and Cadence import manifests flatten the same branch-comparison demand
summaries on strategy tradeoff rows and selected strategy-recommendation
review/import rows, while retaining the full
`source_branch_comparison` row for audit.
Reduced-capacity allocation accepts explicit per-contact capacity requirements
from direct contact fields, nested `throughput_model`, `capacity_model`, or
`activity_context` fields. Nested provider-style requirements carry
`required_capacity_fraction_source` values such as `throughput_model`,
`capacity_model`, or `activity_context` into allocation, review, and import
rows. Declared capacity requirements and contact-supplied station capacity
annotations are unit-interval values; out-of-range numeric values become
invalid allocation inputs rather than clamped planning demand. When callers
declare `default_required_capacity_fraction`,
reduced-capacity packing can use that planning-grade default for contacts that
lack explicit per-contact capacity requirements. Rows using the default carry
`required_capacity_fraction_source: default_reduced_capacity_policy`, and the
pack ledger records `default_required_capacity_fraction`; this remains a
declared artifact policy, not a calibrated link-budget model. Operator-review
and Cadence-import capacity-pack handoff rows now promote the same
`default_required_capacity_fraction` as a schema-visible unit-interval field,
while retaining the full source pack row for audit.
Allocation rows also promote contact/command feedback evidence from top-level
contact fields or metadata, normalizing trimmed case-insensitive JSON-style false values and
numeric-string confidence factors before policy, review, and import handoff.
Approval-policy action rules can now match
`station_calendar_trust_boundary_status` / `station_calendar_trust_boundary_statuses`
from allocation activity context, allowing missing provider-calendar trust
boundaries to be routed explicitly instead of only preserved as passive
evidence. Rules can also match `station_calendar_direction` /
`station_calendar_directions` separately from contact `direction` /
`directions`, so applied provider-calendar direction evidence can drive review
without conflating it with the requested contact direction. The same policy surface now covers contact-contention resource scope,
selection reason, selected priority source, ambiguous resolution status/issue,
station-calendar provider IDs, provider entry IDs, reservation IDs, and
declared/missing trust-boundary status lists, so provider-specific contention
and duplicate-contact identity issues can be routed without executing any
workflow. Contact-contention groups and recommendations also preserve plural
`actual_data_rate_throughput_derivations` rows for provider rate-duration
throughput reconstruction, so aggregate contention throughput can be reviewed
without losing the source contact and formula evidence. Rule matches sort canonically over those contention routing fields,
including provider-calendar identity lists, so repeated matches remain stable
even when equivalent review inputs arrive in a different order. The built-in
ground-network allocation bundle now uses that surface to require review for
plain same-station contact-contention groups and recommendations,
command-direction provider-calendar evidence, and declared provider-calendar
contention, route invalid contact-contention inputs to ground-network review, and
block duplicate contact identity contention until manual resolution.
Approval-policy action rules can also match contention overlap-pressure
thresholds (`contention_window_s_min`, `total_contact_duration_s_min`,
`overlap_duration_s_min`, `max_concurrent_contacts_min`, and
`overlap_contact_pair_count_min`) so severe overlap groups become routing
behavior instead of passive report annotations. The built-in ground-network
bundle uses that surface to route high-overlap station contention to a priority
ground-network queue while leaving ordinary same-station contention on the
normal review rule, and the mission-ops escalation bundle applies the same
priority routing alongside its generic contact-execution coordination rule.
When `resource_summaries` are supplied to allocation, the same artifact embeds
the resulting `resource_filter_report.v1` and converts resource-suppressed
contacts into blocked allocation rows. Those rows preserve
`resource_blocking_dimension`, source quality, trust-boundary status, margins,
battery capacity, battery energy used, battery state of charge, spacecraft mode,
availability flags, and `source_resource_suppression` through operator-review
and Cadence-import rows. This is still a planning-grade availability/margin
boundary, not a resource roll-forward or subsystem simulation.
Allocated contacts that pass the optional resource filter also retain the
matched `source_resource_summary` and resource evidence on the returned contact,
allocation row, operator-review row, and Cadence-import row, so a usable contact
can be audited against the external resource summary that made it eligible.
Executable validation treats allocation summary and trust-boundary count fields
as integer counts, matching the exported JSON Schema and avoiding float-shaped
queue totals in Cadence-facing handoffs.
CandidateRefresh rebuilds preserved compact contact-allocation direction routes
from the authoritative direction, station-pressure, reservation-conflict, and
provider-reservation field maps at flattened-source and replay boundaries.
Explicit compact count maps retain occurrence counts even when stable contact-ID
lists de-duplicate identities; nested provider maps continue to derive route
evidence when direct maps are absent. Stale supplied route-only entries cannot
create allocation pressure, and compact schema validation requires a supplied
route map to equal the canonical rebuild.
Base allocation direction counts and contact-ID lists are canonicalized through
the shared provider aliases after raw report merges and again at compact replay
boundaries. Counts require positive integer evidence; each sorted unique stable
ID list requires a positive local direction count and cannot exceed that
occurrence count. Count-only directions remain scalar pressure and do not emit
identity routes, while valid merged counts may exceed de-duplicated ID lists.
Base allocation status, effective-status, and reason count maps likewise retain
only positive integer evidence after raw merges and at compact replay
boundaries. String-equivalent keys merge by occurrence count, including custom
status and reason values, while zero-only maps cannot create branch-local
allocation pressure. Each independently preserved map must also total no more
occurrences than a positive allocation row count; partial reason maps and custom
status keys remain valid within that bound. Compact schema validation enforces
the same canonical correlation.
Blocked and deferred row scalars are also correlated as mutually exclusive
effective states: both must be nonnegative and their sum cannot exceed the
allocation row count. An all-zero pair remains valid without positive row
identity, but positive scalar pressure requires a positive row total. Invalid
pairs collapse to zero before branch-local pressure evaluation, and compact
schema validation rejects the contradictory source values.
Primary allocated, returned-allocated, deferred, blocked, and policy-blocked
contact-ID lists are canonical sorted unique stable identities at raw and
compact replay boundaries. Identity-only and count-only evidence remain usable;
when both are present, an occurrence count may exceed de-duplicated identity
cardinality but cannot be smaller. Replay drops only an undersized scalar while
preserving valid identity pressure, and compact schema validation rejects the
stale count/list pair.
Primary outcome station maps canonicalize stable station keys and sorted unique
stable contact IDs, then rebuild each top-level identity union from direct plus
routed evidence. Route-only compact evidence therefore remains usable. A
supplied occurrence count must cover both unique identities and routed
memberships; replay drops an undersized scalar, while compact validation rejects
noncanonical routes or count/route mismatches.
Allocation-reason identity maps likewise canonicalize stable reason keys and
sorted unique stable contact IDs. Count-only and route-only reasons remain
usable independently; when a positive local reason count is present, routed
identity cardinality cannot exceed it. Replay removes only the over-cardinality
route, and compact schema validation rejects the stale reason map.
Review contact IDs likewise remain identity-only evidence through raw,
flattened, and replay summaries, canonicalized as sorted unique stable IDs;
compact validation rejects duplicate, out-of-order, or invalid supplied review
identity instead of fabricating a paired review count.
Station-pressure review identity has an exact unique-contact count: when its ID
list is present, replay canonicalizes stable IDs and derives the count from that
list; scalar-only summaries retain their fallback count. Compact validation
rejects noncanonical IDs or a contradictory supplied count.
Station-pressure direction/station routing canonicalizes direction aliases,
station keys, and stable IDs, then rolls nested routes into both parent maps and
aggregate `direction_routing`. Positive local counts must cover their parent
identity cardinality; count-only and route-only evidence remain usable without
synthesizing an absent count, while compact validation rejects hierarchy drift.
Reservation-conflict identity similarly unifies direct IDs with match-status,
direction, and direction/station routes. Replay canonicalizes stable contact,
reservation, and station IDs plus direction aliases, rebuilds top-level contact
identity from every route, and derives the exact unique conflict count while
retaining scalar-only fallback evidence; compact validation rejects drift.
Its match-status and direction count maps also use canonical positive keys.
Count-only and route-only evidence remain available, while a local count smaller
than its routed contact or reservation identity cardinality is discarded during
replay and rejected in a supplied compact source report.
Nested station-routed conflict IDs also roll up into the canonical direction ID
map, so nested-only conflicts remain visible in aggregate `direction_routing`
without manufacturing an absent local direction count.
Invalid-input, status-blocked, and resource-blocked count/ID pairs use the same
identity-first rule. Their top-level lists remain canonical review evidence when
a compact scalar is absent or undersized; valid occurrence counts may exceed
de-duplicated identity cardinality, and compact schema validation rejects stale
counts or noncanonical blocked-input lists. Resource dimension counts retain
only positive canonical entries. Counted dimension routes cannot exceed their
local occurrence count, while route-only dimension evidence remains usable;
canonical dimension and spacecraft routes contribute to the top-level
resource-blocked identity union before its count is correlated.
Allocation row duplicate-contact and station-calendar overlap/reservation count
fields are also executable integer counts, duplicate-contact collision rows must
preserve candidate count, ID, and source-candidate evidence, and contention
groups/recommendations validate duplicate-contact ID and candidate evidence
before review/import handoff. Timing, throughput, and capacity-fraction fields
remain numeric.
Station-calendar duplicate affected-row collision metadata is likewise
validated as integer, group-consistent index/count evidence with a preserved
base row ID.
Suppressed contact/resource filter rows cross-check station-calendar ambiguity
and reservation count/list pairs exactly, require overlap counts to cover at
least the listed overlap IDs when broader overlap state is preserved, and
duplicate suppressed-candidate collision rows require base candidate and
group-consistent index/count evidence. Resource-filter suppression rows also
preserve applied `station_calendar_directions` through approval context,
operator-review rows, and Cadence-import rows.
It remains a review artifact: allocation rows
do not reserve provider time, mutate schedules, approve contacts, or run a link
budget. Duplicate contact IDs are blocked before station filtering and
contention allocation; the resulting rows keep the duplicated `contact_id` but
receive unique allocation-row IDs plus duplicate-candidate metadata for operator
review. Contact-like inputs missing allocation identity, station, or timing
fields are also preserved as blocked invalid-input rows with
`invalid_contact_input_reason`, `review_status`, and the original
`source_contact_candidate`, so malformed handoff rows become operator-review
evidence instead of disappearing before filtering or contention. Allocation
applies the same stable-ID guard to standalone contact identity fields as the
filter: malformed contact, station, source-window, scenario, and
station-overlay IDs are routed to invalid-input review rows, schema-facing row
fields are sanitized or omitted, and the original malformed handoff remains in
`source_contact_candidate`. Malformed non-map contact handoff rows are retained
as `invalid_contact_shape` rows with raw input evidence instead of crashing
report generation. Terminal or
source approval-rejected contacts are blocked before
station filtering and contention allocation; they remain visible in
`status_blocked_contact_count`, `status_blocked_contact_ids`, and blocked rows
with `contact_status`, `source_approval_status`, and
`contact_allocation_effect_*` fields, but they are not returned as allocated
contacts. Status-blocked realized contacts preserve actual-throughput and
completed-fraction evidence through allocation rows, review rows, and import
rows, while `model_limits` still declare that allocation is not full provider
contact reconciliation. Executable validation checks that
`contact_allocation_report.v1` `model_limits` match
`ContactAllocation.capabilities/0`, so stale capability-limit breadcrumbs fail
schema lint instead of drifting through saved artifacts. When `approval_policy`
is supplied, reviewable allocation rows also carry `approval_status`,
`approval_requirements`, `approval_rule_matches`, and
an embedded `policy_decision.v1` so Cadence can distinguish policy-blocked
contacts from operator-review allocation exceptions. Exported allocation,
contact-filter, and resource-filter schemas reuse the canonical
`policy_decision.v1` shape for direct row-level policy decisions and put the
stable-ID pattern on their top-level invalid/blocked contact and candidate ID
arrays, matching executable lint before those reports are imported. The returned
allocated-contact list excludes rows classified
`blocked_by_policy`, even when the report preserves the row's allocation status
for audit and review. Contact-allocation row `review_status` is constrained to
`accepted_for_planning` or `operator_review_required` by executable validation
and exported JSON Schema. Returned allocated contacts preserve flattened
contention priority evidence (`selected_priority`,
`selected_priority_source`, `deferred_contact_priorities`, and priority-override
count/ID metadata) so callers do not have to reopen the nested
contention-resolution report. Contention
resolution policy can also provide mission-specific contact priority overrides
with `contact_priorities`, `contact_priority_overrides`, `priority_overrides`,
or `priority_by_contact_id`; those overrides appear as
`policy_contact_priority` evidence, with override counts and contact IDs carried
through recommendations, operator-review rows, and Cadence-import rows; malformed
override keys or nonnumeric values are preserved as ignored priority-override
warning evidence at the same boundaries. The
resolution contract schema exports those override fields and executable lint
rejects mismatched override counts or contact-ID lists.
V1 campaign and
candidate-refresh artifacts pass their approval policy into embedded allocation
reports; candidate refresh evaluates post-resource-filter contact candidates
for allocation while adding contact-filtered station suppressions back into the
allocation report as blocked review rows, so ground-network-suppressed,
deferred, and policy-blocked contacts remain visible as allocation evidence
before the final `candidate_activities` and `contact_intents` surfaces keep
only effectively allocated contacts.
Candidate refresh and standalone contact allocation can also consume declared
singular or list-valued `station_calendar_provider.v1` artifacts directly, normalizing them into the same
ground-network interval overlay used by contact filtering and allocation while
preserving provider provenance, provider-entry identity, reservation identity,
and trust-boundary evidence. Provider entry timing aliases
and capacity fractions accept clean numeric strings before interval validation
and reduced-capacity classification, while candidate refresh, contact filtering,
contact-intent generation, command-window review, link-capacity summaries,
allocation, and contention grouping accept provider direction aliases including
whitespace or hyphenated forms such as `Down Link`, `Up Link`, and `Track-ing`,
and policy matching uses the same canonical direction alias surface for
contact-direction and station-calendar direction selectors, including command,
tracking, and health-check forms, plus clean numeric-string contact timing
aliases before review/import handoff;
malformed numeric strings remain missing or invalid provider evidence.
The nested `station_calendar_report.v1` inside an allocation report receives
the same approval policy, so reserved overlaps, outages, and severe capacity
reductions retain policy-rule evidence before allocation rows are flattened for
review. Allocation rows also carry provider-normalized
`station_calendar_provider_id` and `station_calendar_provider_entry_id` values
at the top level so review and import adapters do not need to reopen nested
station-calendar source rows for provider provenance. The embedded
`contact_filter_report.v1` also receives that approval
policy, so downlink suppressions caused by unavailable, reserved, or zero-
capacity station time keep their source policy evidence inside the allocation
artifact before they become blocked allocation rows. Station-calendar,
contact-filter, contact-allocation, and resource-filter
approval requirements now preserve station-calendar entry IDs, overlap counts,
overlap availabilities, ambiguous-entry markers, reservation IDs, reserver
lists, reservation statuses, and contact identity/timing/source-window fields
in their `activity_context` fields, so policy decisions can be audited without
reopening the nested report. Station-calendar requirements also preserve
command/uplink affected contacts as `command_review` authority boundaries when
command/contact authority policy is supplied. Allocation rows
preserve the same station-calendar context so operator-review and import rows
can carry reservation and ambiguity evidence without reopening the nested
report. Station-calendar, contact-filter, contention, allocation, and
link-capacity rows also preserve schema-safe provider result labels from scalar,
list-valued, or map-valued provider payloads,
contact/command success flags, feedback confidence factors, and source labels
into policy
`activity_context`, operator-review rows, and Cadence-import rows, so failed or
low-confidence contact evidence remains reviewable after communications review without
executing commands or reserving station time. Status-blocked or
approval-policy-blocked realized contacts are blocked before station allocation
and also preserve `actual_throughput_mb` or provider-style actual-downlink,
delivered, and received aliases, actual data-rate plus duration, plus `completed_fraction` or provider-style
completion aliases into the allocation row, approval context, operator-review
row, and Cadence-import row, keeping delivered-throughput and partial-contact
evidence visible without treating allocation as a realized-provider
reconciliation model. Out-of-range completion fractions and contact/command
success factors become invalid contact-allocation inputs with the original
source contact preserved for review instead of being clamped into row evidence.
Allocation rows also preserve required/candidate
downlink completion, shortfall/status, and source-lineage fields through the
same approval, review, and import handoff. When a declared station calendar
overlaps the terminal
contact, the status-blocked row also keeps reservation, availability, trust, and
source-calendar context for operator audit without returning that contact to
allocation; the report's `model_limits` still declare no full realized-contact
reconciliation model. Allocation reports keep the raw
`allocation_status` for
planner selection compatibility and add `effective_allocation_status` plus
returned and policy-blocked allocated-contact counts so policy-blocked
selections are not mistaken for usable contacts. Returned allocated contacts now
also carry effective allocation status, review status, selected/deferred
contention context, and row-level approval requirements, rule matches, and
policy decisions so downstream planners do not have to rejoin against the
report rows. They also expose row-derived
`allocation_status_counts`, `effective_allocation_status_counts`, and
`allocation_reason_counts` maps plus `station_reservation_match_status_counts`
with executable validation, so Cadence-facing queues can route allocated,
deferred, blocked, policy-blocked, matched-reservation, and
reservation-overlap contacts without recounting report rows. The
standalone `contact_allocation_report_v1.json` fixture exercises that policy
path for a reserved station overlap.

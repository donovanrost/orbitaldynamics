# Station Calendar Report

`OrbitalDynamics.station_calendar_ground_network/1` converts declared
singular or list-valued `station_calendar_provider.v1` artifacts into the ground-network interval shape
used by repair, allocation, and station-calendar overlays, enforcing the same
stable-ID, trust-boundary, and unit-interval capacity boundaries as the provider
schema. Provider artifacts must declare either `trust_boundary` or
`provenance.trust_boundary` before executable validation accepts them.
`OrbitalDynamics.station_calendar_report/3` builds `station_calendar_report.v1`
rows by overlaying declared provider, provider-list, or ground network availability/capacity
intervals onto contact candidates. Affected rows carry stable IDs,
contact/scenario/station IDs, timing, calendar-entry lineage, flattened
provider/entry IDs when the calendar came from `station_calendar_provider.v1`,
availability status, capacity fractions, and ambiguity markers when multiple
same-priority provider rows overlap. The report is advisory and artifact-only;
it does not call provider APIs or reserve station time. Direct
`candidate_refresh.v1` requests merge declared `ground_network` intervals with
`station_calendar_provider.v1` artifacts, preserving provider reservations and
trust-boundary evidence when both inputs describe the same station window. When
a provider-normalized row and a raw `ground_network` row carry the same explicit
calendar-entry identity, the provider row is authoritative for refresh
selection; distinct overlapping rows remain visible as overlap or ambiguity
evidence.
V3 strategy mission-state snapshots may also carry both `station_calendar`
intervals and singular or list-valued `station_calendar_provider` artifacts. The planner normalizes
those declared provider artifacts into branch-local ground-network intervals before
candidate-refresh execution, so derived station outage, reservation, and
reduced-capacity branches can suppress or review generated contacts while
preserving provider provenance and trust-boundary evidence. Plain
`mission_state.station_calendar` intervals remain labeled with that source path
in derived branch metadata instead of being collapsed into generic
`mission_state.ground_network` provenance. Catalog-only
ground-station defaults remain geometry/availability defaults and are removed
from the branch-local overlay when a real event interval overlaps the same
station, so they do not turn declared provider evidence into a missing-boundary
calendar row. Contact-filter suppression rows flatten the applied provider
entry ID as `station_calendar_entry_id`, falling back to the provider row's
stable `id` when the canonical entry field is absent.
V3 branch derivation can also consume prior `source_station_calendar_report`,
canonical `station_calendar_report`, or result-artifact-embedded
`station_calendar_report.v1` affected-contact and provider-contention rows
directly. Reserved, unavailable, and reduced-capacity affected rows become the
same branch-local ground-station reservation, outage, or capacity events used by
mission-state provider inputs, preserving contact timing, station-calendar
entry identity, reservation owner/status, capacity fraction, source-report path,
and report or wrapper trust-boundary evidence. Prior `operator_review_package.v1`
`station_calendar_review` rows and `cadence_import_manifest.v1`
`review_station_calendar` rows replay the same branch-local derivation from
their preserved `source_station_calendar_review` payloads, using the
review/import queue trust boundary when the original report is no longer
attached.
Reports also emit `calendar_entry_trust_boundary_status_counts` for every
declared calendar entry plus `station_calendar_trust_boundary_status_counts`
for affected contacts. This preserves provider trust evidence even when a
calendar artifact has no overlapping contacts, while each affected row still
classifies provider trust provenance as `declared` or `missing`. That row-level
trust-boundary status is preserved through approval context, operator-review
rows, and Cadence-import rows.
Affected rows also preserve the applied provider-calendar entry and the full
set of overlapping provider-calendar entries as structured source evidence, so
operator-review and Cadence-import queues can inspect provider context without
reconstructing it from entry IDs. Those nested source entries and overlaps now
share a typed contract for provider/entry/station/reservation IDs,
availability/status, capacity fraction, reservation owner/status, timing, and
ambiguous-entry summaries, with executable validation on the preserved payloads.
Station-calendar review and import rows also lift provider ID, provider-entry
ID, direction-list, and ambiguous-entry evidence to top-level row fields, so
adapter routing does not need to unpack the nested source station-calendar row
to distinguish provider calendars or command/uplink-scoped station state.
The report also emits artifact-only `provider_calendar_contention_groups` when
declared provider-calendar entries overlap the same station and compatible
direction boundary. Those groups carry typed entry/provider/reservation/trust
boundary lists, overlap pairs, and the preserved source entries, and are routed
as `review_station_provider_contention` station-calendar review rows and
Cadence `review_station_calendar` import rows without calling provider APIs,
reserving station time, mutating schedules, or resolving the conflict. When an
approval policy is supplied, provider-calendar contention groups use the same
station-calendar/provider context selectors as contact-contention rows and carry
approval requirements, rule matches, policy decisions, and escalation metadata
through operator-review and Cadence-import handoffs. V3 branch derivation can
also replay preserved provider-calendar contention groups into branch-local
candidate-refresh station events from their source entries, preserving the
contention group ID, entry IDs, reservation ownership/status, trust boundary,
and overlap window as audit context whether the group is read from the original
station-calendar report or from later operator-review/Cadence-import source
rows.
Provider-shaped availability and status values are canonicalized for case,
whitespace, and hyphen differences before validation, so values such as
`Reserved` or `Reduced-Capacity` preserve the same artifact semantics as
`reserved` and `reduced_capacity`.
Affected rows preserve source contact/command success flags, feedback
confidence factors, source labels, and command result through approval-policy
context, operator-review rows, and Cadence-import rows so station-calendar
handoffs do not lose provider feedback evidence.
Operational timeline activity contexts canonicalize those station-calendar
availability, status, contention, reservation, and nested source-calendar status
tokens again at timeline ingress, preserving schema-facing review/import
semantics when provider-shaped activity rows are supplied directly.
Declared provider entries may also carry scalar `direction`, list-valued
`directions`, or `station_calendar_directions`; all three aliases are
schema-visible, and whitespace or hyphenated direction tokens are canonicalized
before matching. Direction-scoped entries only annotate matching contact rows
after direction aliases are normalized. Station-calendar overlays treat
`command` and `uplink` entries as the same command boundary for annotation and
review while preserving the provider-declared direction list; affected rows
preserve the applied `station_calendar_directions` so review/import queues can
distinguish command/uplink reservations or outages from downlink station state.
Typed tracking and health-check contacts infer `tracking` and `health_check`
calendar directions when the contact row omits an explicit `direction`, so
provider-scoped tracking or health-check station state does not require
synthetic direction fields.
Contact filtering and contact-intent generation keep their narrower
suppressible/contact-request boundaries, use the same provider direction
aliases for downlink, tracking, and health-check rows, and advertise
`provider_direction_aliases` in capabilities. The applied direction list is
preserved through refreshed downlinks, contact-intent rows, contact-allocation
rows, operator-review rows, and Cadence-import rows.
Reserved-overlap approval context also preserves singular reservation owner,
status, and `station_reservation_match_status`, so policy decisions can
distinguish owned reservation time from conflicting reserved time without
reopening the affected-contact row.
Branch-authored station outage and reservation risk context preserves the same
station-calendar entry/provider identity, provider entry identity, calendar
directions, calendar status, provider trust-boundary status, reservation owner,
status, and match-status fields, so provider-scoped approval rules can match and
echo that evidence without reopening raw branch events.
Campaign and repair-time embedded station-calendar reports pass their approval
policy into the same affected-row classification used by the standalone API and
reuse the same overlap, ambiguity, reservation-list, and duplicate-row
semantics. Executable validation checks report-level `model_limits` against
`OrbitalDynamics.Communications.StationCalendar.capabilities/0`, so standalone
and embedded overlays stay aligned with the declared provider-only boundary.
Station-calendar operator-review rows lift the matched policy
escalation queue, role, authority, and SLA from policy decisions, and Cadence
import rows preserve that same `source_policy_escalation` context so adapters
can route reservation, outage, or severe-capacity review without unpacking the
full policy decision.
Repair-time embedded overlays also treat station-backed `planned_contact` rows
as contact rows, so downlink/contact handoff candidates receive the same
availability, reservation, and capacity annotations as native downlink rows.
Declared provider entries can also mark station time as `reserved`; affected
rows then carry `reserved_overlap` contention metadata, reservation IDs, owner
labels, and reservation status for review/import without mutating provider
calendars. When duplicate contact IDs overlap the same calendar entry, the
report keeps all affected contacts and suffixes affected-row IDs
deterministically while preserving the original `contact_id`.
Executable validation treats station-calendar contact/calendar/affected counts,
trust-boundary count maps, duplicate-row counts, and affected-row overlap counts
as integer counts while leaving duration, overlap timing, and capacity fractions
numeric. Affected-row validation now also types direction lists, contact and
command feedback confidence factors, reservation and ambiguity evidence,
trust/provenance fields, and nested source station-calendar entries and overlap
rows. It also cross-checks `affected_contact_count` against affected rows,
`calendar_entry_trust_boundary_status_counts` against `calendar_entry_count`,
`station_calendar_trust_boundary_status_counts` against row-derived trust
status counts, duplicate affected-row totals and affected duration against
emitted rows, and overlap, ambiguity, and reservation counts against their
corresponding ID lists.

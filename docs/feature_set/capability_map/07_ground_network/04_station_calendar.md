# Station Calendar and Provider Boundaries

Models availability/capacity intervals.

## Core modules and entry points

- `StationCalendar`, `OrbitalDynamics.station_calendar_ground_network/1`, and `OrbitalDynamics.station_calendar_report/3` can normalize declared provider calendar artifacts — including list-valued provider handoffs — into ground-network intervals.
- They build the same schema-validated, artifact-only overlay from declared provider or ground-network intervals.
- Existing `station_calendar_report.v1` artifacts are accepted by
  `StationCalendar.report/1` and `OrbitalDynamics.station_calendar_report/1` as
  idempotent handoff inputs before any raw contact/calendar overlay is derived.

## Repair-time consumption (V2 and V3)

- V2 repair and V3 branch repair preserve source contact intents and source contact-filter reports from candidate-refresh artifacts.
- V2 repair can also consume repair-time `ground_network` or `station_calendar` intervals, annotate source contact candidates, and emit a `source_station_calendar_report` — **without suppressing candidates or reserving station time**.
- Declared `station_calendar_provider.v1` artifacts can be normalized into the same repair-time station-calendar interval shape **without network calls or provider reservations**, and now have executable schema/export contracts for both provider input entries and `station_calendar_report.v1` overlay output.
- `station_calendar_report.v1` runtime validation and schema export pin the
  artifact-only overlay model, so stale model identifiers fail before
  reservation-overlap rows or provider-contention evidence are trusted.
- Direct adapter normalization enforces the same stable-ID and unit-interval capacity boundaries as the provider schema, including provider `capacity_pack_capacity_fraction` evidence normalized into canonical station capacity.

## Merging declared sources (direct refresh)

- Direct candidate refresh merges declared `ground_network` intervals with `station_calendar_provider.v1` artifacts instead of treating either source as an exclusive calendar.
- Same-ID direct rows are replaced by the provider-normalized row, so partner provenance, trust boundary, and provider-entry identity remain authoritative.
- Distinct overlapping rows still surface as reviewable overlap or ambiguity context.

## V3 strategy mission-state snapshots

- V3 strategy mission-state snapshots can carry both `station_calendar` intervals and singular or list-valued `station_calendar_provider` artifacts, which are normalized into additive branch-local ground-network overlays before candidate refresh.
- Standalone candidate refresh consumes top-level, mission-state, and accepted-state `station_calendar` interval lists, plus singular or list-valued station-calendar provider fallbacks, through the same station overlay path as `ground_network`.
- As a result, derived outage, reservation, and reduced-capacity branches preserve provider provenance and trust-boundary evidence through contact-filter review.
- V3 branch derivation preserves `mission_state.station_calendar` as the branch `derived_source` instead of relabeling authored calendar intervals as generic ground-network rows.
- Duplicate same-station mission-state outage/reservation/capacity branch IDs are disambiguated by their timing, capacity, reservation, source, and trust-boundary evidence, so separate ground-network intervals do not collapse before branch comparison.

## Replay of embedded prior reports

- Prior `source_station_calendar_report`, canonical `station_calendar_report`, or `station_calendar_report.v1` sections embedded in prior `source_result_artifact` / `result_artifact` wrappers now derive the same branch-local outage, reservation, provider-contention, or reduced-capacity refreshes.
- Station-calendar entry, reservation, capacity, trust-boundary, and source-report lineage is preserved.
- Station-calendar replay summaries preserve affected contact IDs and contact-ID maps by station-calendar status, ground station, and availability alongside the aggregate status/station/availability counts.
- Affected-contact replay summaries preserve station-calendar entry IDs and entry-ID maps by status, ground station, and availability, so the pressure row can be traced back to the causing calendar entry.
- Affected-contact replay summaries preserve direction counts plus contact, station-calendar entry, reservation-ID, and capacity-fraction maps by direction, so pressure can be scoped to uplink/downlink/tracking families.
- Reserved affected-contact replay summaries preserve station-reservation IDs and reservation-ID maps by status, ground station, and availability without reserving provider time.
- Reserved affected-contact replay summaries preserve reserved-by owner counts plus contact, station-calendar entry, and reservation-ID maps by reserved-by owner for owner-level triage.
- Reserved affected-contact replay summaries preserve reservation expiration seconds and the earliest expiration deadline for deadline triage without extending or releasing the reservation.
- Reduced-capacity affected-contact replay summaries preserve station capacity fractions, the minimum fraction, and capacity-fraction maps by status, ground station, and availability.
- Provider-contention replay summaries preserve group IDs and embedded source station-calendar entry IDs alongside provider/station contention count maps, without granting provider-write authority.
- Provider-contention replay summaries preserve contention capacity fractions, the minimum contention fraction, and capacity-fraction maps by provider and ground station for reduced-capacity contention triage.
- Provider-contention replay summaries preserve direction counts plus contention group, source-entry, and capacity-fraction maps by direction, so multi-provider pressure can be scoped to uplink/downlink/tracking families.
- Case, whitespace, hyphen, atom, and outage/down/offline availability variants are canonicalized before branch-event typing, so provider-shaped station-calendar evidence cannot miss branch-local candidate refresh.
- Prior `operator_review_package.v1` `station_calendar_review` rows and `cadence_import_manifest.v1` `review_station_calendar` rows that preserve `source_station_calendar_review` evidence replay the same branch-local pressure derivation with review/import queue source paths and trust boundaries.

## Operator-review counters

- Operator-review scalar handoff counters — including command-window, station-calendar, contention, suppression, and review counts — export and validate as non-negative integers.
- Row-level contact, selected-contact, observation/downlink, resource/activity, and overlap-pressure counters also export and validate as non-negative integers.

## Direction scope and aliases

- Station-calendar overlays treat `command` and `uplink` scoped entries as the same command boundary for annotation/review, while preserving the provider-declared direction list.
- `StationCalendar.capabilities/0` advertises the concrete command-contact direction set.
- Provider direction aliases (`direction`, `directions`, and `station_calendar_directions`) are schema-visible, including whitespace or hyphenated provider tokens such as `Down Link` and `Track-ing`.
- These are normalized before station-calendar, candidate-refresh, contact-filter, and contact-intent matching, with `provider_direction_aliases` advertised in the relevant capabilities.
- Contact intents preserve normalized `station_calendar_directions` through approval context, review rows, and Cadence import rows.

## Trust status and provider entry identity

- Catalog-only ground-station defaults do not downgrade declared provider trust status when a real branch-local calendar interval overlaps the same station.
- Contact-filter suppression rows flatten the applied provider entry ID as `station_calendar_entry_id`, even when the provider used `id` rather than the canonical field name, or nested that provider identity under `source_station_calendar_entry`.
- This lets review/import queues route by stable calendar entry without reopening nested source evidence, including invalid contact-filter review rows.

## Reservations and contention

- Declared provider entries can mark reserved station time, so reports expose artifact-only `reserved_overlap` contention metadata, reservation IDs, owner labels, and reservation status, plus overlap start/end/duration impact metadata — **without claiming live provider reservations**.
- Candidate-refresh station-reservation replay preserves provider-contention
  provider and ground-station routing maps from reservation reports, so
  branch-local reservation review pressure can be routed without mutating
  provider calendars or accepting reservations.
- The same replay preserves reservation IDs by match status and reservation
  status, so review queues can route overlap/status-specific reservation
  evidence without reopening provider rows.
- Affected contact IDs and contact IDs by reservation match status/status are
  preserved alongside those reservation-ID maps, so review queues can route the
  affected contacts directly.
- Candidate-refresh station-reservation replay preserves affected-contact
  direction counts and contact-ID maps by direction, so downlink, command,
  tracking, and health-check reservation pressure can be routed without
  reopening provider rows.
- Owner labels are also summarized as reserved-by counts, affected-contact owner
  maps, and reservation-ID owner maps for owner-specific review routing, without
  treating the artifact as provider reservation authority.
- Expiration evidence is summarized as normalized reservation expiration seconds
  and the earliest expiration deadline through the validated
  `station_reservation_review_summary.v1` contract with exact StationCalendar
  `model_limits`, so review queues can sort deadline pressure without
  recalculating provider rows.
- `StationCalendar.reservation_hold_summary/1`/`2`/`3` and `OrbitalDynamics.station_reservation_hold_summary/1`/`2`/`3` publish the validated `station_reservation_hold_summary.v1` contract with exact StationCalendar `model_limits`, reservation-hold-only counts, hold IDs, owner/status maps, expiration routing, and review contact IDs derived from station-reservation rows without provider writes or schedule mutation.
- `StationCalendar.reservation_hold_import_readiness_summary/1`/`2`/`3` and `OrbitalDynamics.station_reservation_hold_import_readiness_summary/1`/`2`/`3` publish the validated `station_reservation_hold_import_readiness_summary.v1` contract with exact StationCalendar `model_limits`, reservation-hold review-only import-readiness counts, action/status/expiration/owner routing, contact routing, readiness rows, and explicit no-provider-write/no-Cadence-write/no-reservation-acceptance assumptions derived from rows.
- Provider counteroffer review summaries now publish the validated `provider_counteroffer_review_summary.v1` contract, deriving review status, counteroffer status maps, negotiation-state maps, lock-deadline routing, and review rows from normalized counteroffer rows.
- Provider counteroffer reports expose `StationCalendar.provider_counteroffer_import_readiness_summary/1`/`2` and `OrbitalDynamics.provider_counteroffer_import_readiness_summary/1`/`2`, a compact review-only import-readiness view with action/status counts, counteroffer ID routing, lock-deadline routing, and explicit no-provider-write/no-Cadence-write/no-offer-acceptance assumptions. These summaries publish the validated `provider_counteroffer_import_readiness_summary.v1` contract so readiness counts, import classification, and ID routing are row-derived.
- Provider counteroffer plan-impact summaries now publish the validated `provider_counteroffer_plan_impact_summary.v1` contract, deriving timing-shift counts, cost-delta totals, affected station/provider entry ID sets, impact rows, and lock-deadline routing from normalized counteroffer rows.
- Direct `provider_counteroffer_report.v1` summary inputs normalize row aliases and numeric-string cost/deadline/offered-time values through the same row path before review, import-readiness, or plan-impact summaries derive counts and ID maps; malformed numeric evidence is omitted from schema-visible numeric fields instead of leaking invalid rows.
- Existing compact StationCalendar summaries are accepted as idempotent handoff inputs by their public facades, including `station_calendar_precedence_summary.v1`, `station_reservation_review_summary.v1`, `station_reservation_hold_summary.v1`, `station_reservation_hold_import_readiness_summary.v1`, `provider_counteroffer_review_summary.v1`, `provider_counteroffer_import_readiness_summary.v1`, and `provider_counteroffer_plan_impact_summary.v1`.
- CandidateRefresh accepts direct, accepted-state, mission-state, and result-artifact-wrapped `station_reservation_review_summary.v1` handoffs as compact station-reservation provenance, preserving review rows, source paths, reservation counts, owner/status maps, expiration evidence, and branch-local replay pressure without rerunning reservation matching or mutating station calendars. Compact hold import-readiness handoffs derive import-status, required-action, and direction routing maps from `import_readiness_rows` when present, so stale top-level hold-routing maps cannot steer branch-local import-review queues.
- CandidateRefresh accepts direct, accepted-state, mission-state, and result-artifact-wrapped `provider_counteroffer_review_summary.v1` handoffs as compact provider-counteroffer provenance, preserving review rows, source paths, review status, negotiation-state maps, lock-deadline evidence, and branch-local replay pressure without accepting offers or mutating schedules.
- Existing `provider_counteroffer_report.v1` artifacts are accepted by `StationCalendar.provider_counteroffer_report/1` and `OrbitalDynamics.provider_counteroffer_report/1` as idempotent handoff inputs before any station-calendar or provider rows are replayed.
- Contact-allocation provider-counteroffer rows preserve the same offered
  start/end seconds and start/end/duration timing deltas through allocation
  review/import handoff, without accepting offers or mutating schedules.
- Provider outage-style availability aliases (`outage`, `down`, and `offline`, including case/spacing variants) canonicalize to unavailable station state before precedence is applied.
- Reservation overlap IDs, owners, and statuses remain visible even when a higher-priority outage or maintenance event is the applied station-calendar event.

## Precedence and affected-contact rows

- Affected-contact rows expose the applied precedence rank and availability token, so review queues can route unavailable-over-reserved conflicts without replaying provider-calendar ordering.
- `StationCalendar.precedence_summary/1`/`3` and `OrbitalDynamics.station_calendar_precedence_summary/1`/`3` publish the validated `station_calendar_precedence_summary.v1` contract with applied/overlap availability counts, applied-status counts, contact ID maps, and reserved-under-higher-precedence availability/status routing from `station_calendar_report.v1` affected rows without provider reservation or schedule mutation.
- Station calendar reports can be normalized into `operator_review_package.v1` `station_calendar_review` rows for affected contact review/import queues, and now preserve the full overlapping calendar entry IDs/availability set while applying the highest-priority event to each contact.
- Candidate-refresh-generated downlink candidates classify reserved station overlaps with `station_reservation_match_status` before contact/resource filtering, allocation, review, or import handoff.

## Confidence evidence

- Affected-contact `contact_success_factor` and `command_success_factor` values are bounded as unit-interval confidence evidence before review/import handoff.
- Out-of-range confidence is preserved as invalid feedback evidence on the station-calendar review/import row, instead of being clamped into policy context.

## Ambiguity and shared overlay path

- Same-priority overlapping station-calendar entries are marked as ambiguous, instead of choosing arbitrary capacity, reservation, or provider-entry metadata.
- Campaign and repair-time embedded station-calendar reports reuse the same shared overlay path rather than carrying planner-local matching semantics.
- V2 repair `source_station_calendar_report` affected contacts are lifted into top-level `station_calendar_review` and Cadence `review_station_calendar` rows with repair-source provenance and reservation metadata.
- V1 campaign `station_calendar_report` affected contacts now use the same top-level review/import surface with campaign-source provenance.

## ID disambiguation

- Affected-contact row IDs are disambiguated when duplicate contact IDs overlap the same calendar entry, preserving all rows while avoiding review/import ID collisions.
- V3 branch-local station-calendar pressure replay disambiguates duplicate source/canonical/review/import branch IDs for the same affected contact or provider-contention group, so independent calendar evidence is not collapsed before branch comparison.

## Approval policy classification

- Supplying an approval policy classifies affected contacts with `approval_requirements`, approval-rule matches, and `policy_decision.v1` evidence for unavailable station time, reserved overlaps, and severe capacity reductions.
- `command`/`uplink` affected contacts use `command_review` requirements for command-authority policy bundles.
- V1 campaign and repair-time station-calendar reports pass their approval policy into the same classification path.
- Repair-time overlays now annotate station-backed `planned_contact` rows consistently with the standalone adapter, with schema-validated `model_limits` copied from `StationCalendar.capabilities/0`.

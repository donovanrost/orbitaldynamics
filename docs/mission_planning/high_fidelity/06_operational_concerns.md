# Operational Concerns

## Operational Risk Model

Operational planning should score and explain risk, not only pass or fail
constraints.

Risk dimensions:

- probability of contact failure
- probability of data loss
- probability of power reserve violation
- probability of missed objective
- probability of maneuver underperformance
- risk exposure duration
- risk severity
- mission-priority impact
- recoverability
- operator workload impact
- approval burden
- schedule churn
- degraded-mode exposure

Risk artifacts should include:

- risk type
- affected spacecraft or asset
- affected activity
- severity
- likelihood or confidence
- exposure interval
- mitigation
- recoverability
- explanation
- model/provenance references

The first implementation can be deterministic and qualitative. The important
feature is structured, explainable risk.

## Latency and Timeliness

Mission planning depends on stale or fresh operational inputs.

The mature planner should track freshness for:

- accepted orbit state
- covariance or state uncertainty
- spacecraft mode and health
- battery/resource telemetry
- recorder/storage telemetry
- payload availability
- ground-station calendars
- provider reservations
- weather or contact-risk data
- mission objectives
- policy bundles
- command dictionary/configuration packages

Planning artifacts should expose:

- input age
- maximum allowed age
- stale-input warnings
- command upload deadlines
- contact scheduling lock deadlines
- data delivery deadlines
- plan generation deadlines
- time remaining until plan becomes unusable

Timeliness should affect recommendations. A high-scoring plan based on stale
state may need review or may be blocked.

## State Estimation and OD Handoff

High-fidelity planning needs an explicit flight-dynamics handoff boundary.

Feature areas:

- predicted orbit state
- accepted orbit state
- covariance handoff
- OD solution lineage
- state-estimate source quality
- maneuver reconstruction
- post-contact update requirements
- post-maneuver OD update requirements
- stale ephemeris risk
- predicted-vs-accepted residuals
- ephemeris validity windows
- handoff authority

The planner should distinguish analysis predictions from accepted operational
state. Plans that depend on stale or provisional OD should carry appropriate
risk and review requirements.

## Human Workload and Approval Burden

The best plan is not always the highest-scoring technical plan. Operational
cost matters.

Feature areas:

- number of approvals required
- approval authority levels
- operator workload score
- manual intervention count
- contact-change count
- command-product impact count
- timeline churn
- procedure count
- shift handover impact
- overnight or weekend staffing concerns
- review queue assignment
- approval SLA risk

Planning artifacts should make approval burden visible so V3 strategy can
choose a lower-risk, lower-workload plan when mission value is similar.

## Ground Segment Reality

Ground planning includes more than geometric contact windows.

Feature areas:

- station equipment availability
- antenna availability
- modem/baseband availability
- network routing constraints
- ground software availability
- provider lead times
- scheduling lock deadlines
- cancellation policies
- station maintenance calendars
- station reservation ownership

Station-calendar precedence summaries expose unavailable/maintenance-over-
reserved and reduced-capacity overlap routing from declared calendar evidence
without making provider reservations or mutating schedules. Their exported
schema pins the artifact-only precedence-summary model and exact
`model_limits`, matching runtime validation for schema-only handoff checks.
Station-calendar report schema export also pins the artifact-only overlay model,
matching runtime validation before provider-reservation or contention rows are
trusted.
- regional weather risk
- RF interference risk
- data delivery paths
- file delivery latency
- processing pipeline latency
- ground-contact staffing assumptions

OrbitalDynamics should model enough ground reality to recommend contacts and
surface conflicts, while Cadence or external provider systems remain the
authoritative scheduling and reservation systems.
Contact-intent summaries are artifact-only demand handoffs: they expose
contact IDs by ground station and direction, capacity-pack demand by station
and direction, required-capacity source routing, and exact generated
`model_limits` without reserving provider time or mutating schedules.
Contact-allocation summaries are artifact-only routing aids: they expose
allocated, returned, deferred, blocked, policy-blocked, invalid-input,
duplicate-contact-ID, status-blocked, resource-blocked, reduced-capacity-packed, and
reduced-capacity-deferred contact ID sets, plus allocated/returned/
policy-blocked allocation counts, declared blocked/deferred contact counts,
capacity-pack status counts, and
declared allocation-status and effective allocation-status counts,
contact IDs by pack status/source plus required-capacity source counts and
capacity-pack contact counts, reduced-capacity pack group counts/status/ID routing plus
general allocated/returned/deferred/blocked/policy-blocked station routing,
invalid/status/resource-blocked count and contact-ID
routing with resource-blocked dimension/spacecraft maps, reduced-capacity
packed/deferred ID routing, allocation-reason contact-ID maps, exact generated
contact-allocation report/summary, station-pressure summary, and capacity-pack
summary, plus reservation-conflict and provider-reservation request summary
`model_limits`, and capacity-pack selected/deferred station routing, including
selected/deferred demand and
all-contact plus selected/deferred contact IDs by station for candidate-refresh replay queues, plus station-pressure contact IDs by
ground station, availability, precedence availability, precedence rank, and
review requirement, plus generic allocation-review contact IDs for
candidate-refresh replay queues, plus
station-reservation status and reservation owner, plus reservation ID sets by
match status, status, and owner, with reservation-conflict contact IDs and
reservation IDs by match status, and station-reservation status/owner maps,
plus reservation expiration status/deadline maps and review-time active/expired
classification,
preserved for candidate-refresh replay queues.
Declared allocation-status,
effective-status, allocation-reason, capacity-pack, reservation-match count
maps, and scalar allocation/contact counters are derived from normalized rows
or pack groups so stale top-level report summaries do not leak into the routing
aid. `ContactAllocation.capabilities/0` advertises the capacity-pack row
statuses, reduced-capacity pack-group statuses, required-capacity source values,
and required/default required-capacity value paths used by those summaries; the
capacity-pack summary carries those values in optional assumptions so adapter
handoffs can validate stale present metadata without rejecting older summaries
that omit it.
It also advertises the reservation match, reservation-conflict, and
reservation-expiration status vocabularies used by reservation-conflict
summaries, keeping that routing artifact-only rather than provider authority.
Reservation-conflict summaries carry those vocabularies plus provider direction
aliases in optional assumptions so stale present metadata is schema-checkable
without rejecting older summaries that omit it.
Provider-reservation request summaries carry the capability-declared
request-status vocabulary, station-reservation match statuses, and provider
direction aliases in optional assumptions so adapter handoffs can validate
stale present metadata without rejecting older summaries that omit it.
Summaries do not reserve provider time, mutate schedules, or approve contacts.
Station-reservation summaries now publish validated
`station_reservation_report.v1` artifacts for affected reservation overlaps and
provider-calendar contention groups, with row-derived reservation count/status
and reservation-ID checks while preserving the no-provider-write boundary.
Station-reservation review summaries now publish validated
`station_reservation_review_summary.v1` artifacts with row-derived review
status, expiration routing, and review rows under the same boundary, with schema
export pinning the artifact-only review-summary model used by runtime
validation.
Contact-contention resolution summaries follow the same boundary for selected,
deferred, review, and ambiguous duplicate contact IDs; they route operator and
import queues without suppressing candidates or accepting provider time. They
derive conflict-group and recommendation counts from recommendation rows, so
stale top-level resolution counts cannot change routing summaries, and schema
export pins the exact ContactContention `model_limits` used by generated
summaries.
`ContactContention.capabilities/0` advertises the direct and nested
required-capacity fraction/percent paths used by capacity-pack demand totals,
and contention resolution summaries route required-capacity demand by
selected/deferred status plus source counts and contact IDs by source for
review/import triage.
Contact-intent summaries now carry station-capacity and required-capacity alias
path assumptions directly in the artifact, with runtime validation pinning stale
values when present, while preserving the no-provider-reservation and
no-schedule-mutation boundary.
Link-capacity summaries likewise derive contact counters, ignored-contact
reason counts, selected/required/actual evidence counters, invalid-input
counters, and station-reservation match counts from station rows or evidence
rows, while report and summary schema export pins exact link-capacity
`model_limits` against executable validation. They also carry exact
link-capacity station-capacity value paths, station unavailable aliases,
availability precedence, and provider-direction aliases in optional artifact
assumptions, with runtime validation rejecting stale values when present while
preserving older handoffs that omit them. Candidate-refresh
contact-allocation replay preserves general
station-reservation match-status counts and contact/reservation ID maps
separately from reservation-conflict match-status counts and ID maps.
Resource-flow summaries derive ignored selected-activity
counts, reason counts, and IDs by ignored-effect reason from activity-flow rows, keeping
terminal, rejected, or suppressed zero-effect activities review-visible without
unpacking the full projection.
lists before exposing compact triage maps, so stale top-level report summaries
cannot change adapter routing. `LinkCapacity.capabilities/0` advertises the
actual-throughput, actual data-rate/duration, and completion-fraction aliases
used as artifact-only realized-downlink evidence, without treating those
aliases as full realized-provider reconciliation. Candidate-refresh
storage/downlink pressure replay preserves actual-throughput row-count pressure
from that provenance even when actual delivery rows lack stable contact IDs.

## External Provider Negotiation

Ground-network and service providers may reject, accept, or counter-propose
planner requests.

Feature areas:

- requested contact
- provider accepted contact
- provider rejected contact
- provider counteroffer windows (implemented as artifact-only station-calendar
  evidence carrying counteroffer ID, raw status, normalized negotiation state,
  reason code, cost delta, lock deadline, and offered window seconds through
  station-calendar reports, standalone `provider_counteroffer_report.v1`
  row-derived negotiation-state/cost/lock-deadline summaries, compact
  provider-counteroffer review summaries that classify lock-deadline status
  relative to optional `now_s` with schema export pinning the artifact-only
  review-summary model, compact import-readiness summaries that expose
  review/no-import counteroffer IDs plus import status/action/lock-deadline
  maps with schema export pinning the artifact-only import-readiness summary
  model, compact plan-impact summaries that expose timing-shift and cost-delta
  rows without accepting offers and with schema export pinning the artifact-only
  plan-impact summary model, operator review, CandidateRefresh source-report
  replay, and Cadence-import handoffs; `ContactAllocation.capabilities/0` advertises
  the exact provider-counteroffer handoff field list preserved through
  allocation review/import, and `ContactFilter.capabilities/0` advertises the
  same provider-counteroffer timing-delta handoff fields at suppression);
  capability metadata advertises the public report facades, supported
  negotiation-state values, provider-counteroffer review/import action names,
  and the lock-deadline/import-readiness/plan-impact status vocabularies used
  by those artifact-only summaries)
- reservation hold expiration (implemented as artifact-only evidence on
  station-calendar reservation-hold rows, reports, operator-review rows, and
  Cadence-import handoffs; `StationCalendar.reservation_hold_summary/1`/`2`/`3`
  publishes validated `station_reservation_hold_summary.v1` hold-only
  owner/status/expiration routing without provider reservation authority, with
  schema export pinning the artifact-only hold-summary model and exact
  StationCalendar `model_limits` used by runtime validation;
  `StationCalendar.reservation_hold_import_readiness_summary/1`/`2`/`3`
  publishes validated `station_reservation_hold_import_readiness_summary.v1`
  review-only import routing without provider writes, Cadence writes, or hold
  acceptance, with schema export pinning the artifact-only import-readiness
  model and exact StationCalendar `model_limits` used by runtime validation;
  `ContactIntent.capabilities/0` advertises
  station-reservation expiration handoff aliases
  `station_reservation_expires_at_s`, `reservation_expires_at_s`,
  `reservation_hold_expires_at_s`, `hold_expires_at_s`, `expires_at_s`,
  `expires_at`, and plural `station_calendar_reservation_expires_at_s` overlap
  context as artifact-only evidence; `CommandWindow.capabilities/0` advertises
  the same reservation-expiration aliases for command-window review/import
  handoffs)
- negotiation status
- cancellation policy
- provider reason codes
- price/cost changes
- schedule lock deadlines
- operator approval of counteroffers

The planner now preserves normalized counteroffer negotiation-state evidence for
artifact review. It should also explain how provider counteroffers affect plan
feasibility, cost, and objective satisfaction without
performing provider writes, accepting counteroffers, or mutating schedules. The
current review and plan-impact summaries keep lock-deadline-status,
timing-shift, and cost-delta counteroffer ID sets so review queues can route
impacted offers without reopening every row. Those summaries derive
counteroffer counts, status maps, negotiation-state maps, deadline counts, and
cost totals from rows before exposing routing aids, so stale top-level report
summaries cannot change review or impact queues.

## Inter-Satellite Links and Relay Operations

Modern constellations may use crosslinks, relay spacecraft, or store-and-forward
chains. These are different from direct ground contacts.

Feature areas:

- crosslink windows
- relay routing
- data custody transfer
- store-and-forward chains
- relay spacecraft availability
- relay antenna availability
- multi-hop downlink planning
- relay contention
- relay latency
- custody acknowledgements
- route failure recovery

Planning artifacts should make the data path explicit: source spacecraft,
relay chain, ground downlink, custody status, latency, and risk.
`relay_data_path_summary.v1` provides that artifact-only handoff surface through
`LinkCapacity.relay_data_path_summary/2` and
`OrbitalDynamics.relay_data_path_summary/2`. Its counts, status routing, route
IDs, relay spacecraft IDs, ground-station IDs, latency maxima, and risk rows are
derived from published rows without crosslink visibility modeling, relay
scheduling, custody acknowledgement delivery, provider reservation, or schedule
mutation.

## Space Traffic and Safety

Space traffic safety is a distinct planning concern from nominal orbit
propagation.

Feature areas:

- conjunction screening
- collision avoidance planning
- keep-out zones
- protected orbital regions
- no-maneuver windows
- coordinated maneuver constraints
- post-maneuver OD requirements
- disposal or deorbit constraints
- passivation constraints
- maneuver notification artifacts
- regulatory reporting artifacts
- launch/deployment separation constraints

The planner should be able to block or escalate plans that create unacceptable
conjunction, maneuver, or disposal risk. High-fidelity collision screening may
come from an external SSA/CDM provider behind an adapter contract.

## Fleet Health Strategy

Large-constellation planning should not merely react to degraded spacecraft. It
should preserve fleet health.

Feature areas:

- rotate high-load assets
- preserve aging batteries
- avoid overusing weak spacecraft
- assign low-risk tasks to degraded vehicles
- reserve healthy spacecraft for priority events
- balance payload duty cycles
- balance ground-contact load
- track spacecraft health trends
- forecast fleet capacity under attrition
- choose plans that preserve future flexibility

Fleet health strategy connects resource models, operational risk, and
constellation objectives. Resource-projection capability metadata advertises
the accepted source-quality and trust-boundary alias paths used before
artifact-only resource-pressure provenance routing, without promoting those
summaries into propagated subsystem state. Candidate-refresh storage/downlink
pressure replay keeps all-contact plus selected/deferred capacity-pack station
contact-ID maps, capacity-pack contact counts, per-status demand maps, status
contact-ID maps, required-capacity source counts/contact IDs, packed/deferred ID
sets, reduced-capacity pack group counts/status/ID routing, and ground-station,
source-window, station-calendar entry, provider-entry ID routing by pressure
type, and all/selected/unused capacity-adjusted throughput row counts and station maps inside
that artifact-only
boundary, so station, access-window, and provider queues can remain branch-local
and review-only. It also advertises the planned data-volume
aliases used for storage-production roll-forward and the
actual/delivered/received data-volume aliases retained as audit-only evidence,
with malformed or negative actual-volume evidence routed to operator review
before activity-flow rows are produced, plus estimated/planned
downlink-throughput aliases consumed before capacity-adjusted downlink
roll-forward and declared battery-energy
consumed/generated aliases used before battery state projection. Compact
resource-flow summaries also derive station-calendar direction and
capacity-fraction maps by pressure type from activity-flow rows, keeping
provider capacity provenance reviewable without unpacking each projected
resource row. The same compact projected-resource rows preserve resource source
quality, trust-boundary status, and declared provenance so source review queues
do not need to fall back to the full projection report for basic provenance
triage. Invalid activity and resource-summary inputs remain embedded in compact
flow summaries as review-only rows, preserving source evidence for triage while
excluding those inputs from resource projection math.

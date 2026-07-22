# Candidate Refresh Artifact

`candidate_refresh.v1` is the executable boundary for rebuilding opportunities
from updated state.

## Inputs and provenance

- Accepted planning state or orbit-data input provenance.
- Operational-feedback provenance, including declared/missing trust-boundary
  status when feedback inputs affect refreshed candidates.

## Regenerated candidates

- Regenerated access, visibility, eclipse, and activity candidates.
- Candidate activities with reusable `activity_context` for stable
  activity/timeline identity and source-window provenance.

### Deterministic identity sequencing

Source event results and per-result events are canonicalized before assigning
refreshed window and candidate IDs. As a result, ordering differences in
provider or study output do not change the semantic `*_1`, `*_2`, ... identity
sequence.

### Downlink candidate classification

Generated downlink candidates classify reserved station overlaps with
`station_reservation_match_status`. This lets later diff, filter, allocation,
review, and import surfaces distinguish owned reserved time from unresolved
reserved-station conflicts.

## Contact intents, resources, and allocation

- `contact_intents`, with optional approval-policy evidence.
- `resource_summaries`, contact/resource filter reports, and a nested
  `contact_allocation_report.v1` over raw refreshed contact candidates.
- Final contact activities and intents keep only contacts whose
  `effective_allocation_status` is `allocated`.

## Artifact normalization (review/import queues)

- Standalone candidate-refresh artifacts can be normalized through
  `OrbitalDynamics.operator_review_package/1` and
  `OrbitalDynamics.cadence_import_manifest/2`. This lifts the following into
  **artifact-only** review/import queues:
  - refresh contact intents
  - contact-allocation rows
  - candidate-diff invalidations
  - stale/unknown freshness
  - refresh-budget drops
  - model-acceptance review/blocking rows
  - validation-safety-case evidence review/blocking rows
  - embedded candidate-rejection explanations
  - passive operational-readiness source-report summaries
  - contact/resource suppressions
  - warnings
- Standalone `invalidated_candidate.v1`, `candidate_diff_report.v1`,
  `candidate_rejection_report.v1`, `freshness_report.v1`,
  `refresh_budget_report.v1`, `model_acceptance_report.v1`, and
  `validation_safety_case_summary.v1` artifacts can be normalized directly into
  the same review/import gates when a full refresh wrapper is not available.

## Source-report summaries in refresh provenance

### Candidate diff reports

Source `candidate_diff_report.v1` rows come from branch-local or repair-time
refresh inputs, accepted mission state, or result-artifact wrappers. V2/V3
top-level review/import rows preserve repair or branch scope, and V3
mission-state replacement rows feed branch-local replay.

Candidate-diff replay summaries expose preserved source paths,
retained/new/invalidated counts, diff/invalidated/semantic-change reason maps,
changed-field maps, candidate/station routing maps, trust-boundary evidence, and
branch-local diff/new/invalidated/semantic-change pressure flags. They remain
artifact-only: they do not mutate refresh state, select candidates, write to
Cadence, or regenerate candidates. If no candidate-diff source report is
present, the compact replay summary omits the contract field instead of implying
`candidate_diff_report.v1` provenance.
`OperatorReview.from_candidate_refresh_artifact/1` also lifts direct
`source_candidate_diff_report` and `candidate_diff_report` rows into
`candidate_diff_review` rows with `candidate_refresh.*` source paths, including
list-valued source reports. This preserves source-window lineage for review
without mutating refresh state or selecting candidates.

### Candidate rejection reports

Source `candidate_rejection_report.v1` rows from branch-local or accepted
mission state, plus reports preserved as exact `source_result_artifact` /
`result_artifact` maps or nested inside result-artifact wrapper fields, are
summarized in refresh provenance with rejected, reviewable, invalid-input,
rejection-reason, required-action, path, and trust-boundary counts before any
review/import handoff consumes them.

Candidate-rejection replay summaries expose preserved source paths,
rejected/reviewable/invalid-input counts, rejection reason and required-action
maps, candidate/station routing maps, trust-boundary evidence, and
branch-local rejection/review/invalid-input pressure flags. They remain
artifact-only: they do not mutate refresh state, select candidates, approve
imports, write to Cadence, or regenerate candidates. If no candidate-rejection
source report is present, the compact replay summary omits the contract field
instead of implying `candidate_rejection_report.v1` provenance.
`OperatorReview.from_candidate_refresh_artifact/1` also lifts direct
`source_candidate_rejection_report` and `candidate_rejection_report` rows into
`candidate_rejection_review` rows with `candidate_refresh.*` source paths,
including list-valued source reports. This preserves rejection review pressure
without selecting or importing rejected candidates. Candidate-rejection reports
wrapped in direct/list-valued `source_result_artifact` / `result_artifact`
containers are lifted into the same review-row family with wrapper-qualified
`candidate_refresh.*.candidate_rejection_report.rows` source paths.

### Provider counteroffer reports

Source `provider_counteroffer_report.v1` rows come from branch-local or accepted
mission state, exact `source_result_artifact` / `result_artifact` maps, nested
result-artifact wrapper fields, plus provider-counteroffer rows reconstructed
from operator-review packages and Cadence import manifests. CandidateRefresh
also accepts branch-local or accepted
`source_provider_counteroffer_import_readiness_summary` /
`provider_counteroffer_import_readiness_summary` inputs and
`source_provider_counteroffer_plan_impact_summary` /
`provider_counteroffer_plan_impact_summary` inputs produced from those reports,
replaying their import-readiness and impact rows into the same
provider-counteroffer provenance family with import status/action/lock-deadline
ID maps, import-readiness status/classification maps, plan-impact status, and
affected-ID routing maps. Validated
`provider_counteroffer_import_readiness_summary.v1` and
`provider_counteroffer_plan_impact_summary.v1` inputs preserve that source
contract in replay provenance, while older model-only summaries remain
compatible. These are
summarized in refresh provenance with:

- reviewable counts
- provider status/action count maps
- cost-delta totals
- start/end/duration timing-delta counts
- import-readiness summary/status/classification counts
- provider-counteroffer import status/action/lock-deadline ID maps
- review and no-import-required counteroffer ID sets
- plan-impact summary/status counts
- affected station-calendar/provider-entry IDs
- impact, timing-shift, and cost-delta counteroffer ID sets
- lock-deadline counts
- earliest lock deadline
- paths
- trust-boundary evidence

This happens **without accepting counteroffers or mutating schedules**.

Provider-counteroffer replay summaries expose preserved source paths,
reviewable counts, cost/timing/lock counters, status/action maps, plan-impact
status maps, import-readiness status/classification maps, import
status/action/lock-deadline ID maps, affected station-calendar/provider-entry
IDs, impact/timing/cost counteroffer ID sets, review/no-import counteroffer ID
sets, trust-boundary evidence, and branch-local review/cost/timing/lock/import-
readiness/plan-impact pressure flags. They remain artifact-only: they do not
accept counteroffers, mutate schedules, approve imports, write to Cadence, or
regenerate candidates.
Branch-generated refresh requests preserve direct and `source_result_artifact` /
`result_artifact`-wrapped raw provider-counteroffer reports with
wrapper-qualified source paths, indexed embedded replay copies, row-derived
status/action maps, cost/timing/lock evidence, and inherited trust-boundary
evidence. They also preserve direct and result-artifact-wrapped plan-impact
summaries with wrapper-qualified source paths, affected station/provider maps,
counteroffer ID sets, timing deltas, lock evidence, and inherited
trust-boundary evidence.
Operator-review packages built from candidate-refresh artifacts also lift
direct `source_provider_counteroffer_report` / `provider_counteroffer_report`
rows into `provider_counteroffer_review` rows, preserving source paths,
provider status/action, cost/timing/lock evidence, and source row payloads
without accepting offers or mutating schedules.
They also lift direct `source_provider_counteroffer_plan_impact_summary` /
`provider_counteroffer_plan_impact_summary` impact rows into the same
`provider_counteroffer_review` rows, preserving plan-impact source paths and
counteroffer evidence without accepting offers, mutating schedules, or approving
imports.
Direct `source_provider_counteroffer_import_readiness_summary` /
`provider_counteroffer_import_readiness_summary` inputs preserve review/no-import
counteroffer IDs, import status/action/lock-deadline maps, and
import-readiness status/classification evidence without accepting offers,
mutating schedules, approving imports, or writing to Cadence.
Review-required import-readiness rows can also become V3 provider-counteroffer
pressure branches and score-term penalties, while import-ready/no-action rows
remain replay provenance only.
Provider-counteroffer reports, import-readiness summaries, and plan-impact
summaries preserved as exact `source_result_artifact` / `result_artifact` maps
or nested inside direct/list-valued result-artifact containers are lifted into
the same review-row family with wrapper-qualified `candidate_refresh.*` source
paths.

### Schema validation reports

Source `schema_validation_report.v1` rows come from branch-local or accepted
mission state, result-artifact wrappers, operator-review packages, or Cadence
import manifests. Direct/list-valued `schema_validation_batch_report.v1`
inputs are flattened into their nested schema-validation report entries with
batch-entry paths preserved. They are summarized in refresh provenance with
status, validated contract, validation mode, error, warning, remediation, path,
and trust-boundary counts. This keeps schema-gate evidence visible even before
it is folded into readiness evidence.

Schema-validation replay summaries expose preserved source paths,
status/contract/mode maps, error and warning counts, remediation action/category
and path maps, trust-boundary evidence, and branch-local validation/error/
warning/remediation pressure flags. They remain artifact-only: they do not
mutate refresh state, approve imports, write to Cadence, or regenerate
candidates.
Operator-review packages built from candidate-refresh artifacts also lift
direct `source_schema_validation_batch_report` /
`schema_validation_batch_report` nested failing or warning entries into
`schema_validation_review` rows with indexed
`candidate_refresh.*.reports[N].report` source paths, preserving the
`batch_entry_path` without changing candidate selection or approving imports.

### Readiness and quality-gate summaries

Readiness and quality-gate source-report summaries preserve adapter-boundary
declared, missing, and untrusted count maps alongside their import-status,
freshness, schema-validation, and resource-availability evidence.

Quality-gate summaries derive report status/classification and gate totals from
rows when rows are present, so stale top-level counters do not hide why import
eligibility was review-only or blocked.

Canonical blocked `quality_gate_report.v1` evidence has one additional exact
activity-selection effect: when `source_artifact_type` is
`planned_activity.v1` and the non-empty `source_artifact_id` equals a regenerated
candidate ID, that candidate is removed. Direct, accepted-state, mission-state,
and result-artifact-wrapped reports share the existing resolver and inherited
trust boundary. Nonmatching source IDs and review-only, analysis-only, or passed
reports remain provenance-only; malformed reports are not selection evidence,
and aggregate status and quality-gate row IDs are never interpreted as candidate
identity. A generic compact quality-gate summary alone also remains
provenance-only; the specialized unavailable-resource summary keeps its separate
spacecraft/contact rule below. The rejection row uses
`dropped_by_candidate_scoped_quality_gate` for a matching prior candidate and
preserves report/summary identity, source path, exact candidate ID, and trust
evidence for the existing review/import handoff.

The upstream canonical `operational_readiness_report.v1` has the symmetric
exact-activity rule when it is schema-valid, blocked, scoped to
`planned_activity.v1`, and its non-empty `source_artifact_id` equals the
regenerated candidate ID. This uses the same direct/accepted/mission/result-
wrapper resolver and trust inheritance. Compact readiness summaries, malformed
reports, nonmatching or wrong-type source identity, and nonblocked reports
remain provenance-only. A readiness-only match uses
`dropped_by_candidate_scoped_operational_readiness`, emits a distinct warning,
and preserves the exact report identity, source path, candidate scope, blocked
status, and trust evidence for the same review/import handoff.

`operational_quality_gate_unavailable_resource_summary.v1` has one bounded
selection effect during CandidateRefresh builds: a contact-like regenerated
candidate is removed only when its exact candidate ID occurs under its matching
spacecraft/scenario identity in `blocked_contact_ids_by_spacecraft_id`.
Aggregate unavailable-resource pressure and blocking-dimension maps are not
treated as global blocking evidence, and a contact ID under another spacecraft
does not match. When this summary family is present, the refresh emits a
`candidate_rejection_report.v1` over the evaluated candidates; rejected rows
carry `quality_gate_failed` plus source-summary paths and identities in activity
provenance. This explanation artifact feeds the existing review/import handoff
without granting approval or Cadence-write authority.

The upstream canonical `operational_readiness_report.v1` can drive the same
bounded selection directly when
`evidence.resource_blocked_contact_ids_by_spacecraft_id` is non-empty. This
uses the existing direct/accepted/mission/result-wrapper source resolver and
trust inheritance, so callers do not have to derive the compact quality summary
first. Readiness-only matches use
`dropped_by_operational_readiness_unavailable_resource`; a readiness report
with only aggregate resource pressure remains provenance-only and does not add
a candidate-rejection output.

### Model acceptance reports

Source `model_acceptance_report.v1` rows from branch-local, accepted mission
state, or result-artifact wrappers are summarized in refresh provenance with
intended-use, status, row, validation-record, model, acceptance, review,
blocked, unknown-model, validation-level, path, and trust-boundary counts.
This happens **without certifying models or changing candidate selection**.

Model-acceptance replay summaries expose the preserved source-report paths,
record/model counts, status and intended-use maps, validation-level maps, model
IDs by status/validation/intended use, trust-boundary evidence, and branch-local
review/blocking/unknown-model pressure flags. They remain artifact-only: they do
not certify models, approve imports, regenerate candidates, or write to Cadence.
When model-acceptance rows are present, validation-level counts and model-ID
routing maps are derived from those rows rather than stale top-level aggregates.
Operator-review packages built from candidate-refresh artifacts also lift
direct `source_model_acceptance_report` / `model_acceptance_report` rows that
are review-required or blocked into `model_acceptance_review` rows. The handoff
preserves indexed `candidate_refresh.*.rows` source paths, source row payloads,
intended use, validation level, acceptance status, and report-level count
context without certifying models or approving imports.

### Station reservation reports

Source `station_reservation_report.v1` artifacts supplied directly, from
accepted or mission state, or through result-artifact wrappers are summarized in
refresh provenance with source paths, affected-contact and provider-contention
row counts, affected-contact/provider-contention totals, reservation review
counts, reservation IDs, reservation status maps, match-status maps, expiration
evidence counts, and trust-boundary evidence.
These summaries are artifact-only: they do not reserve provider time, mutate
schedules, approve imports, or regenerate candidates.
Capability metadata advertises `station_reservation_report` as an accepted
CandidateRefresh input alongside the source-report provenance and replay helper.
`OperatorReview.from_candidate_refresh_artifact/1` also lifts direct
`source_station_reservation_report` and `station_reservation_report`
affected-contact and provider-contention rows into `station_reservation_review`
rows with `candidate_refresh.*` source paths. This remains an operator-review
handoff only; it does not reserve provider time or mutate station calendars.
Direct station-reservation hold and hold import-readiness summaries use the same
review handoff: their affected-contact and provider-contention rows become
`station_reservation_review` / `review_station_reservation` rows that preserve
exact StationCalendar `model_limits`, hold review/expiration evidence, import
status, required action, reservation IDs, contact routing, and the
no-provider-write / no-Cadence-write / no-reservation-acceptance assumptions.
The same operator-review handoff accepts station-reservation reports, hold
summaries, and hold import-readiness summaries inside candidate-refresh
`source_result_artifact` / `result_artifact` wrappers, preserving
wrapper-qualified source paths and list indexes.

`CandidateRefresh.station_reservation_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_station_reservation_replay_summary/1` expose
that same provenance as a compact branch-local replay summary. It preserves
station-reservation contract, count, row-count, paths, affected-contact and
provider-contention counts,
affected contact IDs plus contact-ID maps by match status and reservation
status, affected-contact direction counts and contact-ID maps by direction,
provider-contention provider/station routing maps, provider-contention group
IDs, embedded source-entry IDs, provider-entry IDs, and provider-entry maps by
provider/station/direction, review counts,
reservation IDs plus reservation-ID maps by match status and reservation status,
reserved-by counts, contact-ID owner maps, and reservation-ID owner maps,
match/status maps, expiration evidence counts, normalized expiration seconds,
earliest expiration, trust-boundary evidence, and branch-local reservation/
review/expiration/owner/provider-contention pressure booleans without provider
reservation, station-calendar mutation, schedule mutation, candidate selection,
import approval, Cadence writes, or candidate generation.
Preserved expiration evidence counts, expiration timestamps, and earliest
expiration also count as family-level station-reservation pressure even when
affected-contact, review, owner, provider-contention, and reservation-status
evidence is absent.
Capability metadata advertises the
station-reservation branch replay summary so catalog consumers can discover the
same artifact-only routing boundary as the public helper. The replay helper can
also inspect strategy branch `candidate_source` metadata that carries a
`candidate_refresh_request_source_report_summary`, so V3 branches can expose
the same reservation routing view after branch-local refresh derivation.
Branch-generated refreshes also preserve direct and result-artifact-wrapped raw
station-reservation reports with wrapper-qualified request paths and indexed
embedded replay copies, keeping affected-contact/provider-contention counts,
reservation review, direction, owner, match/status, expiration, and
trust-boundary evidence visible in generated candidate-source provenance.
Partial station-reservation source-report family placeholders can preserve the
declared contract, but omit flattened count, row-count, and path fields until
both identity counts are present.
Direct, accepted-state, and mission-state
`source_station_reservation_hold_summary` /
`station_reservation_hold_summary` inputs replay through the same
station-reservation provenance family. CandidateRefresh preserves exact
StationCalendar `model_limits`, hold counts,
affected-contact/provider-contention hold counts, source-summary
model/schema-contract/source-artifact identity maps, hold review status,
expiration counts, earliest hold expiration, hold status/expiration maps,
reservation-hold ID maps by expiration/status/owner/row type/direction,
direction-scoped hold contact routing, review contact IDs, and the
artifact-only no-provider-reservation boundary without accepting reservations
or approving imports. The same replay path accepts those summaries inside
`source_result_artifact` / `result_artifact` wrappers while preserving
wrapper-qualified source paths and list indexes.
Generated V3 branch refresh requests preserve direct mission-state and
result-artifact-wrapped station-reservation hold summaries through the
candidate-source audit path, including hold counts, expiration/status maps,
direction routing, review contact IDs, and inherited wrapper trust-boundary
evidence.
Direct, accepted-state, and mission-state
`source_station_reservation_hold_import_readiness_summary` /
`station_reservation_hold_import_readiness_summary` inputs replay through the
same station-reservation provenance family. CandidateRefresh preserves exact
StationCalendar `model_limits`, hold counts,
source-summary model/schema-contract/source-artifact identity maps,
review-only import-readiness status/classification, required import action
counts, reservation-hold IDs, import-status routing, direction-scoped
hold/contact routing, and the no-provider-write / no-Cadence-write /
no-reservation-acceptance
boundary without accepting reservations or approving imports. The same replay
path accepts those summaries inside `source_result_artifact` / `result_artifact`
wrappers while preserving wrapper-qualified source paths and list indexes.
Branch-generated refresh requests preserve direct source, canonical direct, and
wrapped hold import-readiness summaries with wrapper-qualified request input
paths and inherited trust-boundary evidence.
Capability metadata now advertises the hold import-readiness summary as an
accepted CandidateRefresh input and names its input-provenance handoff semantic
alongside the station-reservation replay maps.

## V3 strategy derivation: branch-local refresh requests

V3 strategy derivation can create branch-local refresh requests from various
mission-state source reports. Each preserves evidence on the branch event
without taking the disallowed action noted.

- **Provider counteroffer rows** — from mission-state
  `provider_counteroffer_report.v1` rows that are reviewable and require
  `review_provider_counteroffer`. Preserves counteroffer ID, timing, cost,
  start/end/duration timing deltas, lock-deadline, provider/station identity,
  trust boundary, and source-report path. Done **without accepting the offer or
  reserving provider time**.
- **Provider counteroffer import-readiness rows** — from mission-state
  `provider_counteroffer_import_readiness_summary.v1` rows that are reviewable
  and require `review_provider_counteroffer`. Preserves import status,
  import-readiness status/classification, lock-deadline status, trust boundary,
  and source-report path. Done **without accepting the offer, approving import,
  writing to Cadence, or reserving provider time**.
- **Schema validation rows** — from mission-state `schema_validation_report.v1`
  error or warning rows. Preserves validation mode/status, validated contract,
  issue path/message, remediation, trust boundary, and source-report path. Done
  **without changing candidate selection**.
- **Operational readiness rows** — from mission-state
  `operational_readiness_report.v1` non-importable summaries and non-passed gate
  rows. Preserves readiness level, import classification, gate
  ID/status/classification, evidence, trust boundary, and source-report path.
  Done **without approving operator actions or writing to Cadence**.
- **Quality gate rows** — from mission-state `quality_gate_report.v1` non-passed
  rows. Preserves gate ID/status/classification, row-derived readiness/count
  context, trust boundary, and source-report path. Done **without approving
  operator actions or writing to Cadence**.
- **Model acceptance rows** — from mission-state `model_acceptance_report.v1`
  rows that require review or are blocked/unknown. Preserves intended use,
  model ID, validation level, acceptance status, trust boundary, and
  source-report path. Done **without certifying models or approving imports**.
- **Validation safety-case evidence** — from mission-state
  `validation_safety_case_summary.v1` evidence that requires review or is
  blocked. Preserves evidence status, input contract, evidence references,
  summary count maps, trust boundary, and source-report path. Done **without
  certifying models or approving imports**.
- **Candidate rejection rows** — from mission-state
  `candidate_rejection_report.v1` rows that are rejected, reviewable, and
  require `review_candidate_rejection`. Preserves candidate ID, rejection
  reasons, trust boundary, and source-report path. Done **without selecting or
  importing the rejected candidate**.

## Freshness and refresh-budget reports

`freshness_report.v1` and `refresh_budget_report.v1` apply when branch-local or
repair-time refresh inputs or accepted mission state are stale/unknown or apply
a deterministic candidate limit. V2/V3 top-level review/import rows preserve
repair or branch scope, and V3 mission-state source reports feed branch-local
refresh derivation. Standalone freshness and refresh-budget reports pin the same
CandidateRefresh model-limit boundary in runtime validation and JSON Schema
export, so schema-only handoffs cannot accept stale model-limit lists.

Freshness replay summaries expose preserved source paths, status maps,
stale/unknown reason lists and count maps, trust-boundary evidence, and
branch-local stale/unknown freshness pressure flags. They remain artifact-only:
they do not mutate refresh state, approve imports, write to Cadence, or
regenerate candidates.

Refresh-budget replay summaries expose preserved source paths, input/kept/
dropped candidate counts, invalid-limit policy reason maps, kept/dropped
candidate IDs, trust-boundary evidence, and branch-local budget/drop/invalid
limit pressure flags. They remain artifact-only: they do not mutate refresh
state, approve imports, write to Cadence, or regenerate candidates.

**Refresh-budget integrity:**

- Refresh-budget input, kept, and dropped counts are non-negative.
- Executable validation enforces
  `input_candidate_count = kept_candidate_count + dropped_candidate_count`, both
  for standalone budget reports and when the report is embedded in a
  `candidate_refresh.v1` wrapper.
- When no explicit candidate limit is configured, the embedded report declares
  `max_candidate_activities` as the post-filter input count.

## Candidate-refresh provenance (audit, no selection change)

Candidate-refresh provenance covers supplied source reports of these families:
candidate-diff, provider-counteroffer, contact-contention, freshness,
refresh-budget, operational-readiness, quality-gate, model-acceptance,
validation-safety-case, resource-projection, resource-filter, and
contact-filter.

It preserves the following for audit **without changing refresh selection**:

- input paths
- counts
- status totals
- contact-contention conflict/invalid-input counts plus ground-station/contact
  routing and required-action maps
- contact-contention resolution recommendation/deferred counts, status/reason
  maps, capacity-pack required-capacity demand totals, and selected/deferred
  per-station demand maps
- candidate-rejection candidate/station routing maps
- readiness gate/evidence counters
- quality-gate row/count-map totals
- constraint metric/resource/spacecraft routing maps
- resource-projection pressure type, spacecraft, and activity routing maps
- resource-filter spacecraft/resource/blocking-dimension routing maps
- link-capacity row/status counts, ground-station/spacecraft counts, contact-ID
  maps by direction/ground station/spacecraft/requirement status,
  source-window ID maps by direction/ground station/spacecraft/requirement
  status, station-calendar/provider-entry ID maps by direction/ground
  station/spacecraft/requirement status, selected/actual contact ID lists and
  count maps, selected/actual source-window ID lists, and selected/actual
  station-calendar/provider-entry ID lists
- link-capacity capacity-adjusted throughput row counts, totals, and station
  totals
- objective/score-term station, target, collection, and source-activity routing
  maps
- contact-allocation station-pressure count/contact-ID maps by ground station,
  availability, precedence availability, precedence rank, station-calendar
  status, and review contact ID set
- contact-allocation blocked/deferred row counts
- contact-allocation reservation-conflict count/contact-ID maps, direction
  routing maps, and reservation IDs by match status
- contact-allocation station-reservation match-status counts with canonical
  contact-ID routes at operator-review and Cadence-import handoff boundaries
- contact-allocation reservation-expiration status and declared/missing contact
  counts with canonical contact-ID routes at those handoff boundaries
- contact-allocation reduced-capacity pack status and contact-status count maps
- contact-allocation capacity-pack required-capacity demand totals plus
  selected/deferred per-station demand maps
- station-calendar affected-contact count maps by ground station and
  availability
- station-calendar precedence-summary applied-status and
  reserved-under-higher-precedence contact/reservation status and owner routing
  maps
- station-calendar provider-contention count maps by provider and ground
  station
- contact-filter suppression-reason contact-ID maps plus station-suppression
  count/contact-ID, station-calendar entry, and reservation-ID maps by ground
  station, availability, and status
- candidate-diff retained/new/invalidated counts, diff/invalidated/semantic
  reason maps, changed-field maps, and candidate/station routing maps
- contact-intent station-feedback status count maps
- resource availability pressure counts
- reason count maps
- sorted reason IDs
- unavailable-resource IDs
- blocking dimension counts
- invalid projection/filter/contact input counts
- model validation-level counts
- suppression reason counts
- trust boundaries

Contact-contention summaries can be replayed directly, from result-artifact
wrappers, or from preserved operator-review/Cadence-import handoff rows.
Contact-allocation reduced-capacity replay also treats row-level or nested
source-contact `capacity_pack_capacity_fraction` evidence as station-capacity
feedback when reconstructing branch-local ground-network entries. Station
calendar source-report replay uses the same raw capacity-pack fraction as typed
station-capacity evidence before filtering refreshed contact candidates,
including compact provider-calendar contention groups that carry group-level
capacity-pack fractions.

Contact-intent source-report provenance preserves row-derived
`required_capacity_fraction` demand from direct intent fields and nested
throughput/capacity/activity context. CandidateRefresh summarizes compact
capacity-pack demand totals, source counts, contact IDs by source, and
per-ground-station demand maps from intent rows, so stale aggregate fields do
not override the replay evidence.

## Resource margin feedback replay

Resource margin feedback replayed from reviewed/imported
`resource_projection_report.v1`, compact
`resource_projection_flow_summary.v1`, or `resource_filter_report.v1` rows is
treated as the current margin signal for candidate-refresh filtering. Flow
summaries are normalized through the resource-projection source-report path so
their projected resource rows can drive branch-local downlink-completion
pressure while preserving source path and trust-boundary provenance. Stale
capacity/used fields from the base summary are not allowed to invalidate that
replayed summary before it can suppress matching candidates.

## Source-report summary index

`CandidateRefresh.source_report_summary/1` and
`OrbitalDynamics.candidate_refresh_source_report_summary/1` expose a compact,
**artifact-only** index of the same source-report provenance from either a
refresh request or built artifact. It includes family, contract, path,
row-count, and report/row-count maps by family, contract, and trust-boundary
status. It also lifts contact-intent station-feedback status/import/policy
maps, contact-contention conflict/invalid-input counts plus
ground-station/contact/action maps, contact-contention-resolution
recommendation/deferred counts plus status/reason maps, contact-contention and
contact-allocation capacity-pack required-capacity demand totals, per-station
maps, selected/deferred contact-ID station maps,
link-capacity row/status counts, ground-station/spacecraft counts,
capacity-adjusted throughput totals/maps, contact-ID maps by direction/ground
station/spacecraft/requirement status, source-window ID maps by
direction/ground station/spacecraft/requirement status,
station-calendar/provider-entry ID maps by direction/ground
station/spacecraft/requirement status, and selected/actual contact count maps,
resource-projection pressure status/type/station/spacecraft/source-activity
maps plus activity-ID maps by status/type/station/spacecraft/direction,
resource-filter suppressed-reason/spacecraft/resource/blocking-dimension maps,
resource-filter suppression-reason/spacecraft/resource/blocking-dimension
candidate-ID maps, contact-filter station-suppression
reason/station/availability/status count, suppression-reason contact-ID,
station/availability/status contact-ID, station-calendar entry, and
reservation-ID maps, station-calendar
affected-contact status/station/availability maps, and station-calendar
provider-contention provider/station maps, candidate-rejection
rejected/reviewable/invalid counters and reason/action/candidate/station maps,
provider-counteroffer review/cost/timing/lock counters, status/action maps, and
plan-impact affected-ID/counteroffer-ID sets, freshness status maps and
stale/unknown reason lists/count maps, refresh-budget input/kept/dropped counters,
invalid-limit reason maps, and kept/dropped candidate IDs, schema-validation
status/contract/mode maps, error/warning/remediation counters, and remediation
action/category/path maps, operational-readiness gate/evidence/import/
freshness/schema/adapter/resource/review routing maps, readiness analysis-mode
maps, quality-gate readiness/status/gate/import/freshness/schema/adapter/
resource/source-readiness routing maps, quality-gate analysis-mode maps,
model-acceptance status/intended-use/validation-level maps, model
counters, and model-ID routing maps, validation-safety-case status/evidence/
input-contract/schema/fixture routing maps and counters, objective-satisfaction/
tradeoff/score-term gap counters and station/target/collection maps, aggregate
objective-gap downlink/target/collection gap counts plus combined
station/target/collection/source-activity routing maps, command-window feedback
counts/input keys, maneuver-review success/uncertainty feedback counts/input
keys and maneuver-ID maps, timeline-feedback activity/import-status maps,
timeline-diff removed/changed/feedback/duplicate routing counts and maps,
timeline-transition application selected-activity/status/decision/action/
duplicate routing counts and maps, operational-timeline operational-kind, activity-status,
approval-status, required-action, and Cadence-import-status maps, source
counts, and contact IDs by source from the same row-derived provenance,
**without replaying refresh generation**.
Timeline-diff and operational-timeline operational-feedback provenance derive
status and required-action maps from rows when rows are present, so stale
top-level timeline aggregates cannot steer branch-local feedback pressure.
Command-window operational-feedback provenance uses the same row-first
required-action rule when command-window rows are present.
Maneuver-review feedback provenance follows that same row-first required-action
boundary for maneuver-review rows.
Top-level `source_report_counts_by_family` and
`source_report_row_counts_by_family` aggregate maps, plus their contract and
trust-boundary-status grouped counterparts, preserve explicit zero count fields
for declared families, but omit families whose count field is missing or nil.

`CandidateRefresh.operational_readiness_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_operational_readiness_replay_summary/1`
expose the operational-readiness slice of that provenance as a branch-local
replay summary. It preserves top-level source-report contract/count/path
rollups, source readiness paths, readiness/import/status maps, gate counts,
analysis-mode counts, import/freshness/schema-validation
evidence, adapter-boundary counts, resource-availability reason maps including
station-specific availability reason counts, review/import action maps, and
timeline-publication context from readiness evidence: publication status,
authority, source-artifact type, source/publication/downstream IDs,
dependency-impact rows and IDs, timeline-diff changed/review counts, changed
field maps, changed/review timeline IDs, and changed-field timeline routing.
It also exposes review/import/resource pressure booleans and branch-local
timeline-publication pressure, dependency-pressure, changed-field-pressure,
invalidation-pressure, and review-pressure booleans without approving operator actions,
writing to Cadence, or regenerating candidates. The replay helper can inspect
V3 branch `candidate_source` metadata that carries
`candidate_refresh_request_source_report_summary`, so strategy-derived branch
refreshes preserve operational-readiness review and import-routing evidence
through the branch provenance boundary. The resource pressure boolean is true
for resource/station availability reason maps, unavailable-resource IDs, or
blocking-dimension maps even when the aggregate resource-availability pressure
count is absent.
When the branch `operational_readiness_report` source-report family is
non-empty, the helper labels its output source and replay scope as
candidate-source summary metadata, treats partial non-empty branch families as
authoritative, and falls back to provenance labels for absent or empty branch
families.
Branch-generated refresh requests preserve direct and result-artifact-wrapped
operational-readiness reports with wrapper-qualified request input paths and
indexed embedded replay copies.
Preserved review-type and source-review-type maps count as review pressure, and
preserved import-action maps count as import pressure, even when aggregate
review/import counters are absent or zero.
Candidate-refresh operator-review packages also lift operational-readiness
reports wrapped in direct/list-valued `source_result_artifact` /
`result_artifact` containers into `operational_readiness_review` summary and
gate rows with wrapper-qualified `candidate_refresh.*` source paths, preserving
readiness, import, gate, and resource-pressure context without approving
operator actions.
When operational-readiness provenance is absent, the replay summary omits the
contract field rather than defaulting to `operational_readiness_report.v1`.
`CandidateRefresh.source_report_summary/1` also exposes compact top-level
operational-readiness contract/count/row-count/path rollups for source-report
provenance. Compact operational-readiness source-count/source-row-count and
source-path fields require complete source-report identity (`count` and
`row_count` present), so partial placeholders preserve only the declared
contract while explicit zero counts and explicit empty paths remain replayable
identity.
Capability metadata advertises `operational_readiness_report` as an accepted
CandidateRefresh input alongside operational-readiness replay provenance.

`CandidateRefresh.candidate_diff_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_candidate_diff_replay_summary/1` expose the
candidate-diff slice as a branch-local replay summary. It preserves source diff
contract, count, row-count, paths, retained/new/invalidated counts,
diff/invalidated/semantic-change reason maps, changed-field maps,
candidate/station routing maps, trust-boundary evidence, and branch-local diff
pressure booleans without mutating refresh state, selecting candidates, writing
to Cadence, or regenerating candidates.
Preserved diff, invalidated, semantic-change, changed-field, candidate, and
station routing maps can drive branch-local pressure when aggregate
retained/new/invalidated counters are absent or zero. The replay helper can
inspect V3 branch `candidate_source` metadata that carries
`candidate_refresh_request_source_report_summary`, so strategy-derived branch
refreshes preserve candidate-diff reasons and changed-field routing through the
branch provenance boundary.
When the branch `candidate_diff_report` source-report family is non-empty, the
helper labels its output source and replay scope as candidate-source summary
metadata, treats partial non-empty branch families as authoritative, and falls
back to provenance labels for absent or empty branch families.
Branch-generated refresh requests also preserve direct mission-state and
result-artifact-wrapped raw `source_candidate_diff_report` /
`candidate_diff_report` inputs, retaining wrapper-qualified request paths,
indexed embedded replay copies, retained/new/invalidated counts, reason and
changed-field maps, candidate/station routing maps, and inherited
trust-boundary evidence for artifact-only replay.
When candidate-diff provenance is absent, the replay summary omits the contract
field rather than defaulting to `candidate_diff_report.v1`, and the aggregate
source-report summary omits the top-level candidate-diff identity rollups
instead of emitting empty contract/count/row-count/path fields. Partial
placeholder provenance may preserve a declared contract, but does not
synthesize count, row-count, or path identity rollups unless both identity
counts are present and non-nil. Explicit zero count and row-count values are
preserved as declared identity, paths remain omitted when the path field is
missing or nil, and an explicit empty path list remains a declared empty path
set. Non-identity diff, invalidated, semantic-change, changed-field,
candidate, and station routing maps remain available to branch-local replay
pressure even when the source-report identity is only partial.
Capability metadata advertises `candidate_diff_report` as an accepted
CandidateRefresh input alongside candidate-diff replay provenance.

`CandidateRefresh.candidate_rejection_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_candidate_rejection_replay_summary/1` expose
the candidate-rejection slice as a branch-local replay summary. It preserves
source report contract, count, row-count, paths,
rejected/reviewable/invalid-input counts, rejection reason and required-action
maps, candidate/station routing maps, trust-boundary evidence, and branch-local
rejection/review/invalid-input pressure booleans without mutating refresh
state, selecting candidates, approving imports, writing to Cadence, or
regenerating candidates. Rejection
reason and required-action maps are derived from rows when row evidence is
present instead of trusted from stale top-level report aggregates. Preserved
reason, required-action, candidate, and station routing maps can also drive
branch-local pressure when aggregate rejected/reviewable/invalid-input counters
are absent or zero. The replay helper can inspect V3 branch `candidate_source`
metadata that carries
`candidate_refresh_request_source_report_summary`, so strategy-derived branch
refreshes preserve rejection reasons and required-action routing through the
branch provenance boundary.
When the branch `candidate_rejection_report` source-report family is non-empty,
the helper labels its output source and replay scope as candidate-source summary
metadata, treats partial non-empty branch families as authoritative, and falls
back to provenance labels for absent or empty branch families.
When candidate-rejection provenance is absent, the replay summary omits the
contract field rather than defaulting to `candidate_rejection_report.v1`, and
the aggregate source-report summary omits the top-level candidate-rejection
count, row-count, and path identity rollups instead of emitting empty identity
fields. Empty or partial placeholder provenance can still preserve a declared
contract, but does not synthesize count, row-count, or path identity rollups
unless both identity counts are present and non-nil. Explicit zero count and
row-count values are preserved as declared identity, paths remain omitted when
the path field is missing or nil, and an explicit empty path list remains a
declared empty path set. Non-identity rejection-reason, required-action,
candidate, and station routing maps remain available to branch-local replay
pressure even when the source-report identity is only partial.
Branch-generated refresh requests also preserve direct mission-state and
result-artifact-wrapped raw `source_candidate_rejection_report` /
`candidate_rejection_report` inputs, retaining wrapper-qualified request paths,
indexed embedded replay copies, rejected/reviewable/invalid-input counts,
rejection-reason and required-action maps, candidate/station routing maps, and
inherited trust-boundary evidence for artifact-only replay.
Capability metadata advertises `candidate_rejection_report` as an accepted
CandidateRefresh input alongside candidate-rejection replay provenance.

`CandidateRefresh.provider_counteroffer_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_provider_counteroffer_replay_summary/1`
expose the provider-counteroffer slice as a branch-local replay summary. It
preserves source report contract, count, row-count, paths, reviewable counts,
cost/timing/lock counters, status/action maps, import-readiness
status/classification maps, import status/action/lock-deadline ID maps,
plan-impact status maps, affected station-calendar/provider-entry IDs,
impact/timing/cost counteroffer ID sets, review/no-import counteroffer ID sets,
trust-boundary evidence, and branch-local
review/cost/timing/lock/import-readiness/plan-impact pressure booleans without
accepting counteroffers, mutating schedules, approving imports, writing to
Cadence, or regenerating candidates.
Counteroffer status and required-action maps are derived from rows when row
evidence is present instead of trusted from stale top-level report aggregates.
The family-level counteroffer pressure boolean is true for preserved
cost/timing counteroffer ID lists, import-readiness status/action maps, and
plan-impact status/affected-ID maps even when aggregate counteroffer counters,
status maps, and required-action maps are absent or zero.
The replay helper can inspect V3 branch `candidate_source` metadata that carries
`candidate_refresh_request_source_report_summary`, so strategy-derived branch
refreshes preserve provider-counteroffer review routing through the branch
provenance boundary. Branch-generated refresh requests also preserve direct
mission-state and result-artifact-wrapped raw provider-counteroffer reports,
keeping wrapper-qualified request paths, indexed embedded replay copies,
row-derived status/action maps, cost/timing/lock evidence, and inherited
trust-boundary evidence in candidate-source replay metadata. The same generated
requests preserve direct and result-artifact-wrapped provider-counteroffer
import-readiness summaries, keeping import-readiness status/classification maps,
import status/action/lock-deadline routing, review/no-import counteroffer IDs,
source paths, and inherited trust-boundary evidence.
When provider-counteroffer provenance is absent, the replay summary omits the
contract field rather than defaulting to `provider_counteroffer_report.v1`.
The aggregate source-report summary also omits the top-level
provider-counteroffer identity rollups instead of emitting empty count,
row-count, or path fields. Partial placeholder provenance may expose an
explicit contract, but does not synthesize count, row-count, or path identity
rollups unless both identity counts are present and non-nil.

`CandidateRefresh.contact_contention_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_contact_contention_replay_summary/1` expose
the contact-contention slice as a branch-local replay summary. It preserves
source report contract, count, row-count, paths, conflict-group and
invalid-contact-input counts, invalid contact input IDs, resource-scope maps,
ground-station/contact routing maps, direction counts/contact-ID maps,
required-action maps, trust-boundary evidence, and branch-local
contention/conflict/invalid-input/review pressure booleans without mutating
contact allocation, selecting
candidates, approving imports, writing to Cadence, or regenerating candidates.
The replay helper can inspect V3 branch `candidate_source` metadata that carries
`candidate_refresh_request_source_report_summary`, so strategy-derived branch
refreshes preserve contact-contention conflict/review pressure through the
branch provenance boundary. Invalid contact input IDs count as branch-local
invalid-input pressure even when aggregate invalid-input counters are absent or
zero.
When the branch `contact_contention_report` source-report family is non-empty,
the helper labels its output source and replay scope as candidate-source
summary metadata, treats partial non-empty branch families as authoritative,
and falls back to provenance labels for absent or empty branch families.
When contact-contention provenance is absent, the replay summary omits the
contract field rather than defaulting to `contact_contention_report.v1`, and the
aggregate source-report summary omits the top-level contact-contention identity
rollups instead of emitting empty count, row-count, or path fields. Partial
placeholder provenance may expose an explicit contract, but does not synthesize
count, row-count, or path identity rollups unless both identity counts are
present and non-nil. Explicit zero count and row-count values are preserved as
declared identity, paths remain omitted when the path field is missing or nil,
and an explicit empty path list remains a declared empty path set. Non-identity
conflict, invalid-contact, resource-scope, station, contact, direction, and
required-action maps remain available to branch-local replay pressure even when
the source-report identity is only partial.
Branch-generated refresh requests also preserve direct mission-state and
result-artifact-wrapped raw `source_contact_contention_report` /
`contact_contention_report` inputs, keeping wrapper-qualified request paths,
indexed embedded replay copies, conflict groups, invalid-contact routing,
direction/resource-scope maps, required-action counts, and inherited
trust-boundary evidence visible to the replay helper.
`OperatorReview.from_candidate_refresh_artifact/1` also lifts direct
`source_contact_contention_report` and `contact_contention_report` conflict
groups and invalid-contact inputs into `contact_contention_review` rows with
`candidate_refresh.*` source paths. This preserves contention review pressure
without mutating contact allocation, selecting candidates, resolving contention,
or writing to Cadence.
The same operator-review handoff accepts contact-contention reports inside
candidate-refresh `source_result_artifact` / `result_artifact` wrappers,
including nested `contact_allocation_report.contact_contention_report`
payloads, while preserving wrapper-qualified source paths.
When contact-contention provenance is absent, the replay summary omits the
contract field rather than defaulting to `contact_contention_report.v1`.
Capability metadata advertises `contact_contention_report` as an accepted
CandidateRefresh input alongside contact-contention replay provenance.

`CandidateRefresh.contact_contention_resolution_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_contact_contention_resolution_replay_summary/1`
expose the contact-contention-resolution slice as a branch-local replay summary.
It preserves source resolution contract, count, row-count, paths,
recommendation/deferred-contact counts,
resolution-status and selection-reason maps, capacity-pack required/selected/
deferred demand totals and station maps, selected/deferred contact-ID sets and
per-station maps, direction counts/contact-ID maps, required-operator-action
counts, trust-boundary evidence, and branch-local
resolution/deferred/capacity-pack/action pressure booleans without mutating
contact allocation, selecting candidates, approving imports, writing to Cadence,
or regenerating candidates.
Flattened partial source-report identity does not synthesize missing
count/row-count/path identity: explicit zero counts are retained, missing or nil
paths remain omitted after valid counts, explicit empty path lists are
preserved, and non-identity status/selection/contact/station/direction/action maps
still drive branch-local replay pressure.
The replay helper can inspect V3 branch `candidate_source` metadata that carries
`candidate_refresh_request_source_report_summary`, so strategy-derived branch
refreshes preserve contention-resolution and capacity-pack pressure through the
branch provenance boundary.
When the branch `contact_contention_resolution_report` source-report family is
non-empty, the helper labels its output source and replay scope as
candidate-source summary metadata, treats partial non-empty branch families as
authoritative, and falls back to provenance labels for absent or empty branch
families.
Branch-generated refresh requests also preserve direct mission-state and
result-artifact-wrapped raw `source_contact_contention_resolution_report` /
`contact_contention_resolution_report` inputs, retaining wrapper-qualified
request paths, indexed embedded replay copies, recommendation/deferred-contact
routing, direction and capacity-pack maps, required-action counts, and inherited
trust-boundary evidence for artifact-only replay.
Capability metadata now advertises `contact_contention_resolution_report` and
the compact `contact_contention_resolution_summary.v1` handoff as accepted
CandidateRefresh inputs alongside the existing source-report provenance and
replay helper. Direct, accepted-state, mission-state, and result-artifact-wrapped
`source_contact_contention_resolution_summary` /
`contact_contention_resolution_summary` inputs replay through the same
contact-contention-resolution provenance family while preserving source-summary
model/contract/artifact-type identity, conflict and recommendation counts,
group/review/ambiguous ID sets, selected/deferred/review contact routing by
group, resource scope, and selection reason, capacity-pack demand totals and
status/station/source maps, action counts and review contact IDs by action,
source paths, exact ContactContention `model_limits`, trust-boundary evidence,
and the artifact-only
no-provider-reservation / no-schedule-mutation boundary without reopening raw
recommendation rows.
Generated V3 branch refresh requests preserve direct mission-state and
result-artifact-wrapped contact-contention resolution summaries through the
candidate-source audit path, including conflict/recommendation counts,
selected/deferred/review contact routing, capacity-pack demand maps, action
counts, source paths, and inherited wrapper trust-boundary evidence.
`OperatorReview.from_candidate_refresh_artifact/1` also lifts direct
`source_contact_contention_resolution_report` and
`contact_contention_resolution_report` recommendations into
`contact_contention_recommendation` rows with `candidate_refresh.*` source
paths. This preserves recommendation review pressure without mutating contact
allocation, selecting candidates, resolving contention, approving imports, or
writing to Cadence.
Direct/list-valued, canonical, exact result-artifact, and nested
result-artifact-wrapped `source_contact_contention_resolution_summary` /
`contact_contention_resolution_summary` inputs now synthesize the same
`contact_contention_recommendation` review rows from compact summary group and
contact maps. `CadenceImport.from_candidate_refresh_artifact/1` carries those
rows as `review_contact_contention_resolution` import rows, preserving
summary-qualified `candidate_refresh.*.summary_recommendations` source paths,
selected/deferred/review contact routing, capacity-pack demand evidence,
source-summary model/contract/artifact-type identity, assumptions, and
source-review-row evidence, including exact ContactContention `model_limits`,
without reopening raw recommendation rows or performing contact allocation,
candidate selection, import approval, Cadence write, provider reservation, or
schedule mutation.
Required-action maps are derived from recommendation rows when row evidence is
present, preventing stale top-level resolution aggregates from steering
branch-local action pressure.
Preserved selected/deferred contact-ID maps and capacity-pack station maps can
also drive branch-local resolution, deferred-contact, and capacity-pack pressure
when aggregate recommendation/deferred counters or demand totals are absent or
zero. Recommendation-level plural required-action lists are folded into the same
row-derived action map.
The same operator-review handoff accepts contact-contention-resolution reports
inside candidate-refresh `source_result_artifact` / `result_artifact` wrappers,
preserving wrapper-qualified source paths and list indexes.
When contact-contention-resolution provenance is absent, the replay summary
omits the contract field rather than defaulting to
`contact_contention_resolution_report.v1`.
Partial contact-contention-resolution source-report family placeholders can
preserve the declared contract, but omit flattened count, row-count, and path
fields until both identity counts are present.

`CandidateRefresh.contact_allocation_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_contact_allocation_replay_summary/1` expose
the contact-allocation slice as a branch-local replay summary. It preserves
source allocation contract, count, row-count, paths, blocked/deferred row
counts, declared allocation-status maps, effective allocation-status maps,
allocation-reason maps,
allocated/returned/policy-blocked
allocated counts, declared deferred/blocked contact counts,
allocated/returned/deferred/blocked/policy-blocked contact
	IDs and ground-station maps, allocation-reason
	contact-ID maps, invalid-input, duplicate-contact-ID,
	status-blocked, and resource-blocked counts and contact IDs, and
	resource-blocked maps by dimension/spacecraft, station-pressure count/contact-ID maps by ground station, availability,
	precedence availability, precedence rank, station-calendar status, generic allocation-review contact IDs,
	direction counts/contact-ID maps, and station-pressure review contact IDs,
	reservation-conflict contact IDs and reservation IDs by match status,
	reservation-conflict direction counts/contact-ID maps,
	general station-reservation match-status counts and contact/reservation ID maps,
station-reservation status/owner counts, reservation IDs, and contact/reservation
ID maps by status and owner,
station-reservation expiration seconds, expiration status counts, earliest
expiration, review-time active/expired classification, and contact/reservation
ID maps by expiration status,
provider-reservation request-ready, review-required, and no-request contact-ID
maps by direction and by direction/ground station,
capacity-pack status maps,
capacity-pack contact counts, required/selected/deferred demand totals,
station/status maps, all-contact and selected/deferred contact-ID station maps,
capacity-pack contact IDs by pack
status/source, required-capacity source counts, and reduced-capacity
packed/deferred ID sets, plus reduced-capacity pack group counts/statuses/IDs,
trust-boundary evidence, and
branch-local allocation/station/capacity pressure booleans without mutating
contact allocation, selecting candidates, approving imports, writing to
Cadence, or regenerating candidates. The family-level contact-allocation
pressure boolean is true for capacity-pack demand/routing evidence even when
blocked/deferred allocation counts and allocation-status maps are absent. When
flattened partial source-report identity is incomplete, explicit zero identity
counts are retained, missing or nil paths remain omitted after valid counts,
explicit empty path lists are preserved, and non-identity capacity-pack,
deferred-contact, station-pressure, reservation-conflict, provider-reservation,
invalid-input, review, and direction/ground-station maps still drive
branch-local replay pressure. When
allocation rows are present, allocation-reason contact IDs, generic
allocation-review contact IDs, declared allocation-status and allocation-reason maps,
declared deferred/blocked contact counts,
capacity-pack status, contact-status maps, and required-capacity source counts
are derived from those rows rather than stale top-level routing
aggregates. The
replay helper can inspect V3 branch `candidate_source` metadata that carries
`candidate_refresh_request_source_report_summary`, so strategy-derived branch
refreshes preserve contact-allocation capacity-pack pressure through the branch
provenance boundary.
When the branch `contact_allocation_report` source-report family is non-empty,
the helper labels its output source and replay scope as candidate-source
summary metadata, treats partial non-empty branch families as authoritative,
and falls back to provenance labels for absent or empty branch families.
When contact-allocation provenance is absent, the replay summary omits the
contract field rather than defaulting to `contact_allocation_report.v1`, and the
aggregate source-report summary omits the top-level contact-allocation identity
rollups instead of emitting empty count, row-count, or path fields. Partial
placeholder provenance may expose an explicit contract, but does not synthesize
count, row-count, or path identity rollups unless both identity counts are
present and non-nil.
Branch-generated refresh requests preserve direct and result-artifact-wrapped
`source_contact_allocation_report` / `contact_allocation_report` inputs with
wrapper-qualified request paths and indexed embedded replay copies, keeping raw
allocation rows, capacity-pack demand/routing, direction routing, station
pressure, and trust-boundary evidence visible to the replay helper.
During CandidateRefresh build, canonical allocation rows with a
`source_resource_suppression` map can also reject a regenerated contact when
the row-derived contact ID and spacecraft identity both match. The resulting
candidate-rejection row preserves the allocation path/source, blocking
dimension, spacecraft scope, and row/report trust evidence; a matching prior
candidate uses `dropped_by_contact_allocation_unavailable_resource`.
The same selection boundary applies when allocation rows round-trip through
`operator_review_package.v1` or `cadence_import_manifest.v1`: reconstruction
retains the embedded blocked status, row scope, suppression, and resource trust,
while rejection provenance names the wrapper-qualified review/import path.
Top-level resource-blocked count/ID maps remain replay provenance only and do
not activate selection without a qualifying row.
Preserved selected/deferred capacity-pack contact-ID station maps,
selected/deferred capacity-pack contact-ID direction maps, deferred-contact ID
maps, station-pressure contact-ID maps, station-pressure review contact IDs, and
reservation-conflict contact IDs also count as the corresponding capacity-pack,
deferred-allocation, station-pressure, and reservation-conflict pressure even
when aggregate counters or demand totals are absent or zero. Invalid contact
input IDs and generic review contact IDs still drive family-level
contact-allocation pressure without granting allocation or import authority.
Direct or result-artifact-wrapped
`source_contact_allocation_provider_reservation_request_summary` /
`contact_allocation_provider_reservation_request_summary` inputs replay through
the same contact-allocation provenance family. The summary publishes the
validated `contact_allocation_provider_reservation_request_summary.v1` contract,
with candidate/request/review/no-request counts, request status, routing maps,
wrapper-qualified source paths, and request/review row subsets derived from the
included allocation rows. Generated provider-reservation request summaries
also carry the exact contact-allocation `model_limits` list, pinned by
executable validation and schema export.
Branch-generated refresh requests preserve direct and `source_result_artifact` /
`result_artifact`-wrapped allocation, station-pressure, reservation-conflict,
capacity-pack, and provider-reservation request summaries with
wrapper-qualified request input paths and inherited trust-boundary evidence.
CandidateRefresh preserves request-ready, review-required, and no-request
contact IDs by direction and by direction/ground station, request/review contact
IDs by station and match status, plus request/review reservation IDs by match
status, while retaining the artifact-only no-provider-reservation /
no-schedule-mutation boundary.
Direct or result-artifact-wrapped `source_contact_allocation_summary` /
`contact_allocation_summary` inputs also replay through the same
contact-allocation provenance family, preserving the validated
`contact_allocation_summary.v1` contract, source paths, trust boundary, source
summary model/schema/source-artifact identity counts, row counts, allocation
status maps, contact ID routing, and artifact-only no allocation/no
candidate-selection boundary.
Direct or result-artifact-wrapped
`source_contact_allocation_station_pressure_summary` /
`contact_allocation_station_pressure_summary` inputs replay through that same
family, preserving the validated
`contact_allocation_station_pressure_summary.v1` contract, source paths, trust
boundary, row counts, station-pressure review contact IDs, precedence
availability/rank maps, station-calendar status maps, direction maps,
direction/ground-station maps, and
station-pressure count/contact-ID maps even when replay uses compact summary
maps rather than reopening raw rows. This remains an artifact-only
no-allocation/no candidate-selection boundary.
Compact no-row station-pressure handoffs derive station-pressure contact and
review-contact counts from present station, direction, nested direction/station,
and review contact-ID maps before falling back to duplicated scalar counters.
Supplied review contact-ID lists merge into a sorted unique review identity and
fix the exact review-contact count, including explicit-empty zero; scalar-only
review inputs retain their additive fallback.
They also publish one canonical top-level `station_pressure_contact_ids` union
across direct identity, review identity, station, availability, precedence,
status, direction, and nested direction/station routes; whenever any such
identity evidence is present, its unique cardinality is the exact
station-pressure contact count.
Direct or result-artifact-wrapped
`source_contact_allocation_reservation_conflict_summary` /
`contact_allocation_reservation_conflict_summary` inputs replay through the same
family, preserving the validated
`contact_allocation_reservation_conflict_summary.v1` contract, source paths,
trust boundary, row counts, conflict/contact/reservation routing maps,
direction-scoped and direction/ground-station conflict contact routing from
compact summary maps, expiration evidence, and the artifact-only
no-allocation/no candidate-selection boundary.
Compact no-row reservation-conflict handoffs derive conflict contact counts
from present conflict contact-ID lists, match-status maps, direction maps, and
nested direction/station maps before falling back to duplicated scalar
counters.
These rows are routed as `station_reservation_review` /
`review_station_reservation` handoffs so unresolved reserved-station overlaps
remain review-only work rather than provider-reservation request candidates.
Direct or result-artifact-wrapped
`source_contact_allocation_capacity_pack_summary` /
`contact_allocation_capacity_pack_summary` inputs replay through the same
family, preserving the validated
`contact_allocation_capacity_pack_summary.v1` contract, source paths, trust
boundary, source summary model/schema/source-artifact identity counts, row
counts, capacity-pack contact/status/station/direction/source maps,
required/selected/deferred capacity demand totals, reduced-capacity pack groups,
group status/count/ID maps from compact summaries, and the artifact-only
no-allocation/no candidate-selection boundary.
Compact no-row capacity-pack handoffs derive capacity-pack contact counts from
present capacity-pack contact-ID maps before falling back to duplicated scalar
counters.
The public contact-allocation report publishes the validated
`contact_allocation_report.v1` contract with exact contact-allocation
`model_limits` pinned by executable validation and schema export.
Flattened source-report summaries expose station-pressure contact counts and
count maps by ground station, availability, precedence availability,
precedence rank, and station-calendar status alongside the corresponding contact-ID maps, preserve
station-pressure and reservation-conflict direction/ground-station routing, and
they expose capacity-pack status and contact-status count maps alongside the
capacity-pack contact-ID status maps. The public contact-allocation summary publishes the
validated `contact_allocation_summary.v1` contract, with allocation,
station-pressure, reservation, capacity-pack, resource-blocked, and review
fields derived from the included allocation rows and reduced-capacity pack
groups, plus exact contact-allocation `model_limits` pinned by executable
validation and schema export. The public station-pressure summary publishes the
validated `contact_allocation_station_pressure_summary.v1` contract, with
input/station-pressure/review counts, contact-ID routing, status/availability
count maps, and review rows derived from the included allocation rows, plus exact
contact-allocation `model_limits` pinned by executable validation and schema
export. The public
reservation-conflict summary publishes the validated
`contact_allocation_reservation_conflict_summary.v1` contract, with
reservation/contact counts, match/status/owner/expiration routing,
conflict/review contact IDs, reservation IDs, and row subsets derived from the
included allocation rows, plus exact contact-allocation `model_limits` pinned
by executable validation and schema export. The public capacity-pack summary
publishes the validated `contact_allocation_capacity_pack_summary.v1` contract,
with contact counts, demand totals, status/station/direction/source routing, pack group IDs,
reduced-capacity pack groups, and review rows derived from the included
allocation rows. Generated capacity-pack summaries also carry the exact
contact-allocation `model_limits` list, pinned by executable validation and
schema export.
Operator-review packages built from candidate-refresh artifacts also lift
direct `source_contact_allocation_report` / `contact_allocation_report` rows and
reduced-capacity pack groups into `contact_allocation_review` and
`contact_allocation_capacity_pack_review` rows, preserving source paths,
allocation status/reason, station/resource/capacity evidence, source row
payloads, allocation summary counts, and reduced-capacity pack direction
routing maps without selecting contacts or mutating allocations.
The packages also expose canonical top-level station-pressure contact IDs
alongside their counts and routing maps, and Cadence-import manifests preserve
that same review identity. When top-level identity is present, both handoffs
derive the count from the sorted unique ID union and require that union to cover
every review, grouped, direction, and nested direction/station route, including
explicit-empty zero; scalar-only inputs retain their summed fallback count.
The canonical review-contact ID union independently fixes the exact review count
when supplied, while review-count-only legacy inputs retain the same fallback.
Station, availability, precedence-availability, precedence-rank, and status maps
apply that correlation per key while retaining additive fallback for keys without
grouped identity evidence.
Direction routes are canonical sorted unique maps; nested direction/station IDs
are also lifted into the matching flat direction while direct flat-only evidence
remains available.
Capacity-pack group IDs likewise form one sorted unique top-level union across
direct and status-routed identity evidence and fix the exact group count,
including explicit-empty zero. Each supplied status route fixes its corresponding
status count. Count-only inputs and status-count keys without identity retain
additive fallback, while top-absent routed legacy artifacts remain valid.
Capacity-pack contact IDs by status are also canonical and fix the corresponding
`capacity_pack_status_counts` entry, including explicit-empty zero; count-only
status keys retain additive fallback.
Required-capacity contact IDs by source apply the same per-key correlation to
`required_capacity_fraction_source_counts`, with canonical identity, exact
identity-backed counts, explicit-empty zero, and count-only fallback.
Direct/list and result-artifact-wrapped `source_contact_allocation_summary` /
`contact_allocation_summary` inputs lift through the same OperatorReview and
CadenceImport handoff. Their validated compact
`contact_allocation_summary.v1` `review_rows` become deterministic
`contact_allocation_review` rows and `review_contact_allocation` import rows
with `candidate_refresh.*.review_rows` source paths, allocation
status/reason, station/direction routing evidence, source-summary contract
identity, and source review rows. This remains artifact-only: it does not
allocate contacts, mutate schedules, approve imports, write Cadence state, or
select candidates.
The same review/import handoff accepts direct/list and result-artifact-wrapped
`source_contact_allocation_station_pressure_summary` /
`contact_allocation_station_pressure_summary`,
`source_contact_allocation_reservation_conflict_summary` /
`contact_allocation_reservation_conflict_summary`, and
`source_contact_allocation_capacity_pack_summary` /
`contact_allocation_capacity_pack_summary` inputs. Station-pressure and
reservation-conflict review subsets become `contact_allocation_review` /
`review_contact_allocation` rows, preserving station precedence, reservation
match/expiration, direction, source-summary contract, and source review-row
evidence. Capacity-pack summaries also lift reduced-capacity pack groups into
`contact_allocation_capacity_pack_review` /
`review_contact_allocation_capacity_pack` rows while preserving pack status,
capacity fraction, group identity, and source-summary evidence. These handoffs
remain artifact-only and do not allocate contacts, mutate schedules, approve
imports, write Cadence state, or select candidates.
Capability metadata advertises `contact_allocation_report` as an accepted
CandidateRefresh input alongside the source-report provenance and replay helper.
Direct provider-reservation request summaries are lifted through the same
contact-allocation review/import handoff: request rows retain
`request_ready` status and review rows retain `review_required` status, while
contact IDs, reservation IDs, match-status routing, the validated source
summary contract, summary context, and the artifact-only no-provider-reservation
/ no-schedule-mutation boundary are preserved for operators. Derived
operator-review packages and Cadence import manifests also expose the
provider-reservation request counts, request-status counts, contact-ID sets,
station/direction/match-status contact-ID maps, and match-status
reservation-ID maps as top-level handoff fields.
Provider-reservation request, review, and no-request contact IDs each form a
sorted unique top-level union across their available direct and routed identity
evidence. Request/review unions include station, direction, nested
direction/station, and match-status routing; no-request unions include direction
and nested direction/station routing. Any supplied identity fixes its exact
contact count, including explicit-empty zero; count-only legacy inputs retain
additive fallback, and top-absent legacy routed artifacts remain valid.
The same operator-review handoff accepts contact-allocation reports inside
candidate-refresh `source_result_artifact` / `result_artifact` wrappers,
preserving wrapper-qualified source paths and stable review IDs.
When contact-allocation provenance is absent, the replay summary omits the
contract field rather than defaulting to `contact_allocation_report.v1`.

`CandidateRefresh.link_capacity_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_link_capacity_replay_summary/1` expose the
link-capacity slice as a branch-local replay summary. It preserves source
link-capacity contract, count, row-count, paths, selected/actual shortfall and
actual-throughput row counts, selected/actual/unused capacity-adjusted
throughput totals plus
station and direction maps, selected/actual contact ID lists and count maps,
selected/actual source-window ID lists, selected/actual station-calendar/
provider-entry ID lists, direction/spacecraft counts, contact-ID maps by
direction/ground station/spacecraft/requirement status,
downlink requirement status maps, source-window ID maps by direction/ground
station/spacecraft/requirement status, station-calendar/provider-entry ID maps
by direction/ground station/spacecraft/requirement status, trust-boundary
evidence, and branch-local link-capacity, throughput, shortfall, and
actual-throughput pressure booleans without mutating contact
allocation, selecting candidates, approving imports, writing to Cadence, or
regenerating candidates. Selected/actual contact count maps also count as
branch-local link-capacity evidence even when row-count and station maps are
absent. Preserved capacity-adjusted throughput totals and per-station maps also
count as family-level link-capacity pressure even when row-count and other
routing/status maps are absent. Direct, accepted-state, mission-state, and
result-artifact-wrapped `source_link_capacity_summary` /
`link_capacity_summary` inputs replay through the same provenance family,
preserving the compact `link_capacity_summary.v1` contract, source-summary
identity, station count, selected/actual shortfall evidence,
capacity-adjusted throughput totals/maps, selected/actual contact IDs, source
paths, exact link-capacity `model_limits`, and trust boundaries without
reopening link-capacity rows. The replay
helper can inspect V3 branch `candidate_source` metadata that carries
`candidate_refresh_request_source_report_summary`, so strategy-derived branch
refreshes preserve link-capacity throughput and shortfall pressure through the
branch provenance boundary. Branch-generated refresh requests preserve direct
mission-state and result-artifact-wrapped raw `source_link_capacity_report` /
`link_capacity_report` inputs with wrapper-qualified request paths, indexed
embedded replay copies, capacity-adjusted throughput totals/maps,
selected/actual shortfall evidence, contact/station/provider routing, exact
link-capacity `model_limits`, and inherited trust-boundary evidence in
candidate-source replay metadata.
When the branch `link_capacity_report` source-report family is non-empty, the
helper labels its output source and replay scope as candidate-source summary
metadata, treats partial non-empty branch families as authoritative, and falls
back to provenance labels for absent or empty branch families.
Operator-review packages built from candidate-refresh artifacts also lift
direct `source_link_capacity_report` / `link_capacity_report` rows into
`link_capacity_review` rows, preserving source paths, station identity,
throughput/shortfall/contact routing, policy evidence, and source row payloads
without mutating contact allocation or selecting candidates.
The same OperatorReview and CadenceImport handoff accepts direct/list and
result-artifact-wrapped `source_link_capacity_summary` /
`link_capacity_summary` inputs. Compact `link_capacity_summary.v1` station
maps become deterministic `link_capacity_review` / `review_link_capacity`
rows with `candidate_refresh.*` source paths, selected/actual shortfall,
capacity-adjusted throughput, selected/actual contact routing, source-summary
contract, assumptions, and source review-row evidence. This remains
artifact-only and does not recalculate link capacity, mutate contact
allocation, select candidates, approve imports, write Cadence state, or mutate
schedules.
Capability metadata advertises `link_capacity_report` and
`link_capacity_summary` as accepted CandidateRefresh inputs alongside the
source-report provenance and replay helper.
The same operator-review handoff accepts link-capacity reports and compact
link-capacity summaries inside candidate-refresh `source_result_artifact` /
`result_artifact` wrappers, preserving wrapper-qualified source paths and list
indexes.
When link-capacity provenance is absent, the replay summary omits the contract
field rather than defaulting to `link_capacity_report.v1`.
Partial link-capacity source-report family placeholders can preserve the
declared contract, but omit flattened count, row-count, and path fields until
both identity counts are present. Explicit zero identity counts are retained,
missing or nil paths remain omitted after valid counts, explicit empty path
lists are preserved, and non-identity throughput, direction, station, contact,
and requirement-status maps still drive branch-local replay pressure.

`CandidateRefresh.contact_filter_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_contact_filter_replay_summary/1` expose the
contact-filter slice as a branch-local replay summary. It preserves source
contact-filter contract, count, row-count, paths, suppressed-candidate and
invalid-contact-input counts, invalid contact input IDs, suppression-reason maps,
suppression-reason
contact-ID maps, direction counts/contact-ID maps, station-suppression
station/availability/status count, contact-ID, station-calendar entry,
station-calendar provider-entry, and reservation-ID maps, trust-boundary
evidence, and branch-local
candidate-suppression,
invalid-input, and station-suppression pressure booleans without mutating
contact allocation, selecting candidates, approving imports, writing to
Cadence, or regenerating candidates. The replay helper can inspect V3 branch
`candidate_source` metadata that carries
`candidate_refresh_request_source_report_summary`, so strategy-derived branch
refreshes preserve contact-filter suppression pressure through the branch
provenance boundary. Branch-generated refresh requests preserve direct and
result-artifact-wrapped mission-state contact-filter reports with
wrapper-qualified request input paths and indexed embedded replay copies, so
suppression, invalid-input, direction, and station-suppression routing remains
visible to `CandidateRefresh.contact_filter_replay_summary/1`.
When the branch `contact_filter_report` source-report family is non-empty, the
helper labels its output source and replay scope as candidate-source summary
metadata, treats partial non-empty branch families as authoritative, and falls
back to provenance labels for absent or empty branch families.
Suppression-reason, direction/contact-ID,
suppression-reason contact-ID, station-suppression station/availability/status
count, contact-ID, station-calendar entry, station-calendar provider-entry, and
reservation-ID maps, and invalid contact input IDs count as branch-local
pressure even when aggregate
suppressed, station, or invalid-input counters are absent or zero.
Operator-review packages built from candidate-refresh artifacts also lift
direct `source_contact_filter_report` / `contact_filter_report` suppressed
candidate rows into `contact_suppression` rows, preserving source paths,
station/reservation context, policy evidence, duplicate or invalid-row context,
and source row payloads without mutating contact allocation or selecting
candidates.
Capability metadata advertises `contact_filter_report` as an accepted
CandidateRefresh input alongside the source-report provenance and replay helper.
The same operator-review handoff accepts contact-filter reports inside
candidate-refresh `source_result_artifact` / `result_artifact` wrappers,
preserving wrapper-qualified source paths and list indexes.
When contact-filter provenance is absent, the replay summary omits the contract
field rather than defaulting to `contact_filter_report.v1`.
Partial contact-filter source-report family placeholders can preserve the
declared contract, but omit flattened count, row-count, and path fields until
both identity counts are present. Explicit zero identity counts are retained,
missing or nil paths remain omitted after valid counts, explicit empty path
lists are preserved, and non-identity suppression, direction, invalid-input, and
station-suppression maps still drive branch-local replay pressure.

`CandidateRefresh.resource_filter_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_resource_filter_replay_summary/1` expose
the resource-filter slice as a branch-local replay summary. It preserves source
resource-filter contract, count, row-count, paths, suppressed-candidate and
invalid-resource-summary-input counts, invalid resource-summary input IDs,
suppression-reason maps,
suppression-reason candidate-ID maps, spacecraft/resource/blocking-dimension
maps and candidate-ID maps, suppressed-candidate direction counts and
candidate-ID maps by direction,
trust-boundary evidence, and branch-local resource-filter, suppression,
invalid-input, and resource-blocking pressure booleans without mutating
resource filtering, selecting candidates, approving imports, writing to
Cadence, or regenerating candidates. Direct, accepted-state, mission-state, and
result-artifact-wrapped `source_resource_filter_summary` /
`resource_filter_summary` inputs replay through the same provenance family,
preserving the compact `resource_filter_summary.v1` contract, source-summary
identity, exact ResourceFilter `model_limits`, review rows, invalid
resource-summary inputs, suppression maps, resource/blocking-dimension routing,
source paths, and trust boundaries without rerunning resource filtering. Direct
and result-artifact-wrapped
`source_resource_filter_report` / `resource_filter_report` inputs also remain
visible through branch-generated refresh requests, including wrapper-qualified
request input paths and indexed embedded replay copies. The replay helper can
inspect V3 branch
`candidate_source` metadata that carries
`candidate_refresh_request_source_report_summary`, so strategy-derived branch
refreshes preserve resource-filter suppression and blocking pressure through the
branch provenance boundary. Branch-generated refresh requests also preserve
direct and `source_result_artifact` / `result_artifact` wrapped
`source_resource_filter_summary` / `resource_filter_summary` inputs with
wrapper-qualified source paths and direct plus inherited trust-boundary evidence.
When the branch `resource_filter_report` source-report family is non-empty, the
helper labels its output source and replay scope as candidate-source summary
metadata, treats partial non-empty branch families as authoritative, and falls
back to provenance labels for absent or empty branch families.
Suppressed-reason, suppression-reason
candidate-ID, spacecraft/resource/blocking-dimension count and candidate-ID
maps, direction/candidate-ID maps, and invalid resource-summary input IDs count
as family-level branch-local pressure even when aggregate suppressed or
invalid-input counters are absent or zero.
Operator-review packages built from candidate-refresh artifacts also lift
direct `source_resource_filter_report` / `resource_filter_report` suppressed
candidate rows and invalid resource-summary inputs into `resource_suppression`
rows, preserving source paths, spacecraft/resource context, policy evidence,
and source row payloads without mutating resource filtering or selecting
candidates.
The same OperatorReview and CadenceImport handoff accepts direct/list and
result-artifact-wrapped `source_resource_filter_summary` /
`resource_filter_summary` inputs. Compact `resource_filter_summary.v1`
`review_rows` and `invalid_resource_summary_inputs` become
`resource_suppression` / `review_resource_suppression` rows with deterministic
`candidate_refresh.*` source paths, suppression reason, resource blocking,
invalid-summary, source-summary contract, assumptions, and source review-row
evidence. This remains artifact-only and does not rerun resource filtering,
select candidates, approve imports, write Cadence state, or mutate schedules.
Capability metadata advertises `resource_filter_report` and
`resource_filter_summary` as accepted CandidateRefresh inputs alongside the
source-report provenance and replay helper.
The same operator-review handoff accepts resource-filter reports and compact
resource-filter summaries inside candidate-refresh `source_result_artifact` /
`result_artifact` wrappers, preserving wrapper-qualified source paths and list
indexes.
When resource-filter provenance is absent, the replay summary omits the
contract field rather than defaulting to `resource_filter_report.v1`.
Partial resource-filter source-report family placeholders can preserve the
declared contract, but omit flattened count, row-count, and path fields until
both identity counts are present. Explicit zero identity counts are retained,
missing or nil paths remain omitted after valid counts, explicit empty path
lists are preserved, and non-identity suppression, resource, blocking-dimension,
direction, and invalid-input maps still drive branch-local replay pressure.

`CandidateRefresh.resource_projection_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_resource_projection_replay_summary/1`
expose the resource-projection slice as a branch-local replay summary. It
preserves source resource-projection contract, count, row-count, paths,
projected-resource and invalid
input counts, source artifact-type and flow-summary model counts, invalid input
ID lists, resource-pressure status/type/activity maps, activity-ID maps by
status/type/station/spacecraft/direction, direction counts, station and spacecraft
maps, source-window/station-calendar/provider and provider-entry routing maps
by pressure status and type derived from rows or preserved summary maps,
trust-boundary evidence, and branch-local
projection, projected-resource, invalid-input, and activity pressure booleans without
mutating resource projection, selecting candidates, approving imports, writing
to Cadence, or regenerating candidates. The family-level resource-projection
pressure boolean is true for resource-pressure activity, activity-ID, direction,
station, spacecraft, source-window, station-calendar, provider, and provider-entry
routing maps, and invalid-input pressure is true for invalid input ID lists even
when projected-resource and invalid-input counts and status/type maps are absent.
When flattened partial source-report identity is incomplete, explicit zero
identity counts are retained, missing or nil paths remain omitted after valid
counts, explicit empty path lists are preserved, and non-identity pressure,
routing, and invalid-input maps still drive branch-local replay pressure.
Raw resource-projection source reports preserve explicit or row-derived invalid
activity/resource-summary input IDs into the same replay provenance.
The replay helper can inspect V3 branch
`candidate_source` metadata that carries
`candidate_refresh_request_source_report_summary`, so strategy-derived branch
refreshes preserve resource-projection pressure through the branch provenance
boundary. Branch-generated refresh requests preserve direct mission-state and
result-artifact-wrapped raw `source_resource_projection_report` /
`resource_projection_report` inputs with wrapper-qualified request paths,
indexed embedded replay copies, projected-resource and invalid-input counts,
resource-pressure status/type/activity/station/spacecraft/direction routing,
source-window/station-calendar/provider/provider-entry routing, and inherited
trust-boundary evidence in candidate-source replay metadata.
When the branch `resource_projection_report` source-report family is non-empty,
the helper labels its output source and replay scope as candidate-source summary
metadata, treats partial non-empty branch families as authoritative, and falls
back to provenance labels for absent or empty branch families.
Operator-review packages built from candidate-refresh artifacts also lift
direct `source_resource_projection_report` / `resource_projection_report`
projected-resource rows, invalid activity inputs, and invalid resource-summary
inputs into `resource_projection_review` rows, preserving source paths,
spacecraft/activity/resource-pressure context, policy evidence, and source row
payloads without mutating resource projection or selecting candidates.
They also lift direct `source_resource_projection_flow_summary` /
`resource_projection_flow_summary` projected resources into the same
`resource_projection_review` rows, preserving flow-summary context, source
artifact type, flow-summary model identity, and indexed `candidate_refresh.*`
source paths without mutating resource projection or selecting candidates.
Capability metadata now advertises `resource_projection_report` and
`resource_projection_flow_summary` as accepted CandidateRefresh inputs and names
their input-provenance handoff semantic.
The operator-review handoff also accepts those resource-projection reports and
flow summaries when they are preserved inside candidate-refresh
`source_result_artifact` / `result_artifact` wrappers, keeping
wrapper-qualified source paths and list indexes intact.
When resource-projection provenance is absent, the replay summary omits the
contract field rather than defaulting to `resource_projection_report.v1`.
Partial resource-projection source-report family placeholders can preserve the
declared contract, but omit flattened count, row-count, and path fields until
both identity counts are present.

`CandidateRefresh.storage_downlink_pressure_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_storage_downlink_pressure_replay_summary/1`
compose contact-allocation, link-capacity, and resource-projection provenance
into a compact storage/downlink replay summary. It preserves source families,
contracts, paths, trust-boundary maps, allocation/capacity-pack pressure,
selected/deferred capacity-pack station and direction demand maps, all-contact
plus selected/deferred capacity-pack station and direction contact-ID maps,
capacity-pack contact counts, per-status demand maps, contact-status count
maps, status contact-ID maps, and reduced-capacity packed/deferred ID sets,
plus reduced-capacity pack group counts/status/ID routing and
required-capacity source counts/contact IDs,
selected/actual downlink shortfall, all/selected/unused capacity-adjusted
throughput row counts plus station and direction maps, link-capacity direction
routing maps,
selected contact count maps, actual-throughput row counts, contact count maps,
contact/source-window/station-calendar entry/provider-entry ID lists and pressure,
station, spacecraft, contact, activity, source-window, station-calendar entry,
provider ID, and provider-entry routing, resource-pressure direction counts and activity-ID maps
by direction, plus storage/downlink
pressure maps without mutating allocation or projection state, selecting
candidates, approving imports, writing to Cadence, or regenerating candidates.
The replay helper can inspect V3 branch `candidate_source` metadata that carries
`candidate_refresh_request_source_report_summary`, so strategy-derived branch
refreshes preserve composed storage/downlink/capacity pressure through the
branch provenance boundary. Capacity-adjusted throughput row-count, station,
or direction evidence contributes to the composed downlink and storage/downlink
pressure flags even when no shortfall row is present. Selected contact count maps
and actual-throughput row, contact count, or ID-list evidence contribute to the
same composed pressure flags without implying a shortfall. Resource-activity routing evidence
contributes to the composed storage/downlink pressure flag even when
storage/downlink status, type, and direction maps are absent.
Aggregate pressure-family count and row-count maps preserve explicit zero
identity for contact-allocation, link-capacity, and resource-projection families,
and the trust-boundary-status count map follows the same declared-count rule,
but missing or nil identity counts are omitted. Explicit empty path lists remain
normalized to an empty aggregate path set while non-identity routing maps can
still drive branch-local storage/downlink pressure.

`CandidateRefresh.station_calendar_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_station_calendar_replay_summary/1` expose
the station-calendar slice as a branch-local replay summary. It preserves
source station-calendar contract, count, row-count, paths, affected-contact IDs
and counts, contact IDs by
station-calendar status, ground station, and availability, affected
station-calendar entry IDs and entry IDs by status/station/availability,
affected station-reservation IDs and reservation IDs by
status/station/availability, affected direction counts plus contact,
calendar-entry, reservation-ID, and capacity-fraction maps by direction,
reserved-by owner counts, and contact, calendar-entry, and reservation-ID maps
by reserved-by owner, reservation
expiration seconds and the earliest reservation expiration deadline, reduced
station capacity fractions from explicit capacity fields or numeric
`availability` aliases, including nested throughput-model, capacity-model,
activity-context, and preserved source station-calendar evidence, with the
minimum fraction and capacity-fraction maps by status/station/availability,
provider-contention counts, provider-contention group IDs and embedded source
entry IDs, provider-entry IDs, provider-contention capacity fractions, minimum
provider-contention capacity fraction, and provider-contention capacity-fraction
maps by provider and station, provider-entry maps by provider and station, plus
provider-contention direction counts and group/source-entry/provider/
provider-entry/capacity-fraction maps by direction when direction evidence is present,
provider/station/status/availability maps, trust-boundary evidence, and
branch-local station-calendar, affected-contact, provider-contention, and
station-availability pressure booleans. Preserved station-capacity maps keyed by
ground station and provider-contention capacity maps keyed by provider, station,
or direction remain station-availability pressure, and preserved provider and
provider-entry routing maps remain provider-contention pressure, even when
aggregate affected or contention counters are absent or zero. The replay summary does not mutate
station calendars or schedules, select candidates, approve imports, write to
Cadence, or regenerate candidates.
`OperatorReview.from_candidate_refresh_artifact/1` also lifts direct
`source_station_calendar_report` and `station_calendar_report` affected-contact
and provider-contention rows into `station_calendar_review` rows with
`candidate_refresh.*` source paths. This is an operator-review handoff only; it
does not mutate station calendars or reserve provider time.
Capability metadata advertises `station_calendar_report` and the compact
`station_calendar_precedence_summary.v1` handoff as accepted CandidateRefresh
inputs alongside the source-report provenance and replay helper. Direct,
accepted-state, mission-state, and result-artifact-wrapped
`source_station_calendar_precedence_summary` / `station_calendar_precedence_summary`
inputs replay as station-calendar source provenance while preserving source
summary model/contract/artifact-type identity, affected-contact counts, applied
and overlap availability maps, higher-precedence reservation contact IDs,
suppressed reservation IDs, reservation-status/owner routing maps, source paths,
exact station-calendar `model_limits`, and trust-boundary evidence. The summary
replay remains artifact-only and does not mutate station calendars, accept
reservations, write to Cadence, or regenerate candidates.
The same operator-review handoff accepts station-calendar reports inside
candidate-refresh `source_result_artifact` / `result_artifact` wrappers,
preserving wrapper-qualified source paths and list indexes.
The replay helper can inspect V3 branch `candidate_source` metadata that carries
`candidate_refresh_request_source_report_summary`, so strategy-derived branch
refreshes preserve station-calendar affected-contact, provider-contention, and
availability pressure through the branch provenance boundary.
Branch-generated refreshes also preserve direct and result-artifact-wrapped raw
station-calendar reports with wrapper-qualified request paths and indexed
embedded replay copies, keeping affected-contact/provider-contention counts,
direction routing, trust-boundary evidence, and artifact-only
no-calendar-mutation assumptions visible in generated candidate-source
provenance.
When station-calendar provenance is absent, the replay summary omits the
contract field rather than defaulting to `station_calendar_report.v1`.
Partial station-calendar source-report family placeholders can preserve the
declared contract, but omit flattened count, row-count, and path fields until
both identity counts are present.

`CandidateRefresh.command_window_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_command_window_replay_summary/1` expose the
command-window slice as a branch-local replay summary. It preserves source
command-window contract, count, row-count, paths, command-feedback counts,
feedback input keys, direction counts plus activity/window ID maps by direction,
required-operator-action counts, trust-boundary evidence, and branch-local
command-window, command-feedback, and command-action pressure booleans without
executing commands, selecting
candidates, approving imports, writing to Cadence, or regenerating candidates.
Preserved feedback input keys count as command-feedback pressure even when the
aggregate command-feedback counter is absent or zero, while preserved routing
and required-action maps continue to drive family and action pressure.
`OperatorReview.from_candidate_refresh_artifact/1` also lifts direct
`source_command_window_report` and `command_window_report` rows, plus
command-window reports preserved in `source_result_artifact` / `result_artifact`
wrappers, into `command_window_review` rows with `candidate_refresh.*` source
paths, including list-valued source reports. This is a review handoff only; it
does not execute commands or write to Cadence.
The replay helper can inspect V3 branch `candidate_source` metadata that carries
`candidate_refresh_request_source_report_summary`, so strategy-derived branch
refreshes preserve command-window feedback and required-action pressure through
the branch provenance boundary.
Branch-generated refreshes also preserve direct and result-artifact-wrapped raw
command-window reports with wrapper-qualified request paths and indexed embedded
replay copies, keeping command-feedback counts, direction routing,
required-action maps, trust-boundary evidence, and artifact-only
no-command-execution assumptions visible in generated candidate-source
provenance.
When command-window provenance is absent, the replay summary omits the contract
field rather than defaulting to `command_window_report.v1`.
Partial command-window source-report family placeholders can preserve the
declared contract, but omit flattened count, row-count, and path fields until
both identity counts are present.
Operational-feedback provenance for source command-window reports derives
required-action maps from rows when rows are present, preventing stale top-level
command-window aggregates from steering branch-local feedback pressure.
Capability metadata advertises `command_window_report` as an accepted
CandidateRefresh input alongside command-window replay provenance and
operational-feedback handoffs.

`CandidateRefresh.maneuver_review_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_maneuver_review_replay_summary/1` expose
the maneuver-review slice as a branch-local replay summary. It preserves source
maneuver-review contract, count, row-count, paths, maneuver-success feedback
counts, execution-uncertainty declared/missing counts, feedback input keys,
row-derived maneuver-ID maps, required-operator-action counts, trust-boundary
evidence, and branch-local maneuver-review, maneuver-feedback,
maneuver-routing, action, and execution-uncertainty pressure booleans without
executing maneuvers, selecting candidates, approving imports, writing to
Cadence, or regenerating candidates.
Preserved `maneuver_success_rate` input keys count as maneuver-feedback
pressure, and preserved `maneuver_execution_uncertainty` input keys count as
execution-uncertainty pressure, even when aggregate feedback or uncertainty
counters are absent or zero.
`OperatorReview.from_candidate_refresh_artifact/1` also lifts direct
`source_maneuver_review_report` and `maneuver_review_report` rows, plus
maneuver-review reports preserved in `source_result_artifact` /
`result_artifact` wrappers, into `maneuver_review` rows with
`candidate_refresh.*` source paths, including list-valued source reports. This
is a review handoff only; it does not execute maneuvers or write to Cadence.
The replay helper can inspect V3 branch `candidate_source` metadata that carries
`candidate_refresh_request_source_report_summary`, so strategy-derived branch
refreshes preserve maneuver-review feedback and uncertainty pressure through
the branch provenance boundary.
Branch-generated refreshes also preserve direct and result-artifact-wrapped raw
maneuver-review reports with wrapper-qualified request paths and indexed
embedded replay copies, keeping maneuver-success feedback, execution-uncertainty
counts, maneuver-ID maps, required-action maps, trust-boundary evidence, and
artifact-only no-maneuver-execution assumptions visible in generated
candidate-source provenance.
When maneuver-review provenance is absent, the replay summary omits the
contract field rather than defaulting to `maneuver_review_report.v1`.
Partial maneuver-review source-report family placeholders can preserve the
declared contract, but omit flattened count, row-count, and path fields until
both identity counts are present.
Operational-feedback provenance for source maneuver-review reports derives
required-action and maneuver-ID maps from rows when rows are present, preventing
stale top-level maneuver-review aggregates from steering branch-local feedback
or routing pressure.
Capability metadata advertises `maneuver_review_report` as an accepted
CandidateRefresh input alongside maneuver-review replay provenance and
operational-feedback handoffs.

`CandidateRefresh.contact_intent_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_contact_intent_replay_summary/1` expose the
contact-intent slice as a branch-local replay summary. It preserves source
contact-intent contract, count, row-count, paths, station-feedback
status/import/policy maps, capacity-pack required-contact counts, required-capacity totals and
per-station, per-direction, and per-direction/per-ground-station maps,
required-capacity source/contact routing maps, all-contact
`contact_ids_by_direction` routing, capacity-pack contact-ID
station/direction/per-direction-station maps, all-contact
`contact_ids_by_ground_station` routing, all-contact
`contact_ids_by_direction_and_ground_station` routing, and a compact
direction-routing map that groups contact count, contact IDs, ground-station
IDs, station-bucketed contact IDs, capacity-pack contact IDs, station-bucketed
capacity-pack contact IDs, and required-capacity fraction by direction/station,
trust-boundary evidence, and branch-local contact-intent, station-feedback,
and capacity-pack pressure booleans without generating contacts, mutating
contact allocation, selecting candidates, approving imports, writing to
Cadence, or regenerating candidates. Direct, accepted-state, mission-state, or
result-artifact-wrapped
`source_contact_intent_summary` / `contact_intent_summary` inputs replay through
the same family, preserving the `contact_intent_summary.v1` contract,
source-summary model/schema/source-artifact identity counts, source paths,
contact-intent row counts, capacity-demand maps, all-contact station/direction
and station-scoped direction routing, and compact direction routing without
reopening raw contact-intent rows. Generated contact-intent summaries also carry the exact contact-intent
`model_limits` list, pinned by executable validation and schema export. The
aggregate source-report summary omits the top-level contact-intent identity
rollups when provenance is absent instead of emitting empty count, row-count, or
path fields. Partial placeholder provenance may expose an explicit contract,
but does not synthesize count, row-count, or path identity rollups unless both
identity counts are present and non-nil. Explicit zero count and row-count
values are preserved as declared identity, paths remain omitted when the path
field is missing or nil, and an explicit empty path list remains a declared
empty path set. Non-identity direction lists, direction counts, contact-ID maps,
and compact direction-routing maps remain available to branch-local replay
pressure even when the source-report identity is only partial. The
family-level contact-intent pressure
boolean is true for capacity-pack source/contact routing maps and per-station
or per-direction contact-ID maps, including all-contact station maps and the
compact station-scoped direction-routing map,
even when capacity totals and station-feedback maps are absent. Flattened
source-report summaries expose those per-station and per-direction all-contact
and capacity-pack contact ID maps, the per-direction/per-ground-station maps,
plus direction-routing maps alongside the nested
`source_reports.contact_intent` provenance.
Compact no-row contact-intent summary handoffs derive replay row counts and
capacity-pack required-contact counts from present all-contact and capacity-pack
contact-ID routing maps before falling back to duplicated scalar counters.
The replay helper can inspect V3 branch
`candidate_source` metadata that carries
`candidate_refresh_request_source_report_summary`, or derive the same family
from raw branch request contact-intent inputs, so strategy-derived branch
refreshes preserve contact-intent station-feedback and import-status routing
through the branch provenance boundary.
Operator-review packages and Cadence import manifests built from
candidate-refresh artifacts also lift direct, accepted-state, mission-state, and
result-artifact-wrapped compact contact-intent summaries into
`contact_intent_review` / `review_contact_intent` handoffs, preserving
`candidate_refresh.*` source paths, direction routing, source-summary context,
capacity-pack contact IDs, and artifact-only no contact-generation,
no-allocation, no-schedule-mutation boundaries. Branch-generated refresh
requests preserve direct and `source_result_artifact` / `result_artifact`
wrapped raw `source_contact_intent`, `contact_intent`, `source_contact_intents`,
and `contact_intents` inputs with wrapper-qualified request paths,
station/direction capacity maps, all-contact direction routing, capacity-pack
contact IDs, and direct plus inherited trust-boundary evidence.
When contact-intent provenance is absent, the replay summary omits the contract
field rather than defaulting to `contact_intent.v1`.

`CandidateRefresh.timeline_diff_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_timeline_diff_replay_summary/1` expose the
timeline-diff slice as a branch-local replay summary. It preserves source
timeline-diff paths, duplicate identity counts/maps, removed downlink/
observation counts, changed downlink/contact/observation/command/maneuver
feedback counts, status/action maps, source/replacement activity-ID routing
maps, trust-boundary evidence, and branch-local timeline-diff,
duplicate-identity, removed-activity, changed-activity, activity-routing, and
operator-review pressure booleans. When rows are present, those activity-ID
maps are derived from row source/replacement activity fields before stale
aggregate fields, without mutating timelines, selecting
candidates, approving imports, writing to Cadence, or regenerating candidates.
The family-level timeline-diff pressure boolean is true for duplicate-scope
evidence even when duplicate, removed, changed, status, action, and activity
routing counts are absent.
`OperatorReview.from_candidate_refresh_artifact/1` also lifts direct
`source_timeline_diff_report` and `timeline_diff_report` review rows, plus
`timeline_diff_summary.v1` compact summaries from direct, accepted-state,
mission-state, exact `source_result_artifact` / `result_artifact` maps, and
wrapped result-artifact summary fields, into
the same timeline-diff source provenance family. Summary replay preserves the
compact summary contract, review rows, aggregate maps, source paths, and trust
boundaries before review/import handoff, without mutating timelines or
selecting candidates.
The replay helper can inspect V3 branch `candidate_source` metadata that carries
`candidate_refresh_request_source_report_summary`, so strategy-derived branch
refreshes preserve timeline-diff duplicate/removed/changed/review pressure
through the branch provenance boundary. Branch-generated refresh requests also
preserve direct and `source_result_artifact` / `result_artifact` wrapped
`source_timeline_diff_report` / `timeline_diff_report` and
`source_timeline_diff_summary` / `timeline_diff_summary` inputs with
wrapper-qualified source paths, row-derived routing evidence, and direct plus
inherited trust-boundary evidence.
When timeline-diff provenance is absent, the replay summary omits the contract
field rather than defaulting to `timeline_diff_report.v1`.
Capability metadata advertises `timeline_diff_report` and
`timeline_diff_summary` as accepted CandidateRefresh inputs alongside
timeline-diff replay provenance and operational-feedback handoffs.

`CandidateRefresh.timeline_integrity_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_timeline_integrity_replay_summary/1` expose
validated `timeline_integrity_report.v1` inputs as branch-local replay
provenance. CandidateRefresh accepts direct, accepted-state, mission-state, and
`source_result_artifact` / `result_artifact` wrapped
`source_timeline_integrity_report` / `timeline_integrity_report` inputs,
preserving source report contract, count, row-count, paths, row-derived
integrity issue and review counts, issue-type/action maps, review
activity/timeline routing,
dependency/exclusivity issue IDs, trust-boundary evidence, and dependency,
exclusivity, review, and family-level pressure booleans without mutating
timelines, selecting candidates, approving imports, writing to Cadence, or
regenerating candidates. Row evidence drives the replay maps when rows are
present, so stale top-level integrity aggregates do not override dependency or
exclusivity routing. The replay helper can inspect V3 branch `candidate_source`
metadata that carries `candidate_refresh_request_source_report_summary`, so
strategy-derived branch refreshes preserve timeline-integrity review,
dependency, and exclusivity pressure through the branch provenance boundary.
When timeline-integrity provenance is absent, the replay summary omits the
contract field rather than defaulting to
`timeline_integrity_report.v1`. The aggregate source-report summary also omits
the top-level timeline-integrity identity rollups instead of emitting empty
count, row-count, or path fields. Partial placeholder provenance may expose an
explicit contract, but does not synthesize count, row-count, or path identity
rollups unless both identity counts are present and non-nil. Explicit zero
count and row-count values are preserved as declared identity, paths remain
omitted when the path field is missing or nil, and an explicit empty path list
remains a declared empty path set. Non-identity status, issue-type,
required-action, review, dependency, and exclusivity routing maps remain
available to branch-local replay pressure even when the source-report identity
is only partial. Capability metadata advertises `timeline_integrity_report` as
an accepted CandidateRefresh input alongside timeline-integrity replay
provenance.
`OperatorReview.from_candidate_refresh_artifact/1` and
`CadenceImport.from_candidate_refresh_artifact/1` also lift direct/list-valued
and wrapped `source_timeline_integrity_report` / `timeline_integrity_report`
artifacts into `timeline_integrity_review` /
`review_timeline_integrity` rows. The handoff preserves dependency,
exclusivity, invalid-input, issue-count, issue-type, required-action, and
source-row evidence with deterministic `candidate_refresh.*` source paths
without applying timeline changes or granting import authority.

`CandidateRefresh.timeline_lifecycle_state_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_timeline_lifecycle_state_replay_summary/1`
expose timeline lifecycle-state summaries as branch-local replay provenance.
CandidateRefresh accepts direct, accepted-state, mission-state, exact
`source_result_artifact` / `result_artifact`, and wrapped
`source_timeline_lifecycle_state_summary` /
`timeline_lifecycle_state_summary` inputs, preserving source paths,
source-summary model/schema identity, top-level source-report
contract/count/row-count/path rollups, planned/realized activity and row
counts, recordable, preserved, review, duplicate-identity, invalid-input counts
and invalid activity input IDs, transition decision/import/action/status/
approval maps, recordable/preserved/review timeline IDs, review activity IDs,
trust-boundary evidence, and review timeline IDs routed by required action and
status/approval transition category, plus lifecycle transition application
provenance counts by helper/category/operator-action reason when source rows
were derived from helper-applied transitions. Compact top-level lifecycle
source-count, source-row-count, and source-path rollups require complete
source-report identity (`count` and `row_count` present); partial placeholders
only expose the declared contract.
For V3 strategy branch refreshes, the replay helper prefers a non-empty
`candidate_source.candidate_refresh_request_source_report_summary.source_reports.timeline_lifecycle_state_summary`
family over provenance, labels the output source and replay scope as
candidate-source summary metadata, and treats partial non-empty branch families
as authoritative while preserving provenance fallback for absent or empty branch
families.
The replay summary exposes branch-local lifecycle-state, review, recordable,
and preservation pressure booleans without applying lifecycle transitions,
mutating timelines, selecting candidates, approving imports, writing to
Cadence, or regenerating candidates. When timeline lifecycle-state provenance
is absent, the replay summary omits the contract field rather than defaulting
to `timeline_lifecycle_state_summary.v1`. Capability metadata advertises
`timeline_lifecycle_state_summary` as an accepted CandidateRefresh input
alongside timeline lifecycle-state replay provenance.
`OperatorReview.from_candidate_refresh_artifact/1` and
`CadenceImport.from_candidate_refresh_artifact/1` also lift those direct/list
and wrapped lifecycle-state summaries into `timeline_lifecycle_state_review`
rows with `candidate_refresh.*` source paths. The handoff preserves source
lifecycle rows, transition decisions, status/approval transitions, required
operator actions, activity/timeline routing, and source-summary context without
granting operator authority or applying lifecycle transitions.
The same CandidateRefresh review/import handoff accepts direct/list-valued,
accepted-state, mission-state, and wrapped `source_timeline_activity_state` /
`timeline_activity_state`,
`source_timeline_activity_status_state` /
`timeline_activity_status_state`, and
`source_timeline_activity_approval_state` /
`timeline_activity_approval_state` artifacts, preserving compact
single-activity state, status-transition, and approval-transition evidence as
lifecycle review/import rows with source artifact identity. It also accepts
direct/list-valued, accepted-state, mission-state, and
wrapped `source_timeline_activity_lifecycle_state` /
`timeline_activity_lifecycle_state` artifacts, preserving single-activity
lock/executed/protection and status/approval transition evidence as lifecycle
review/import rows without requiring a list-level lifecycle summary.
`CandidateRefresh.timeline_activity_lifecycle_state_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_timeline_activity_lifecycle_state_replay_summary/1`
also expose those single-activity lifecycle-state handoffs as source-report
provenance, preserving contract/count/row-count/path identity, model/schema
identity, transition decisions,
operator/import actions, activity/timeline routing, protection evidence, trust
boundaries, invalid-activity input counts and reasons, lifecycle transition
application provenance counts by helper/category/operator-action reason, and
no-mutation/no-authority assumptions.
`CandidateRefresh.source_report_summary/1` flattens the same
`source_report_timeline_activity_lifecycle_state_contract`, `count`,
`row_count`, and `paths` identity fields for compact consumers. Partial
lifecycle-state source-report family placeholders can preserve the declared
contract, but omit flattened count, row-count, and path fields until both
identity counts are present.
For V3 strategy branch refreshes, the replay helper prefers a non-empty
`candidate_source.candidate_refresh_request_source_report_summary.source_reports.timeline_activity_lifecycle_state`
family over provenance, labels the output source and replay scope as
candidate-source summary metadata, and treats partial non-empty branch families
as authoritative while preserving provenance fallback for absent or empty branch
families.

`CandidateRefresh.timeline_activity_precondition_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_timeline_activity_precondition_replay_summary/1`
expose timeline activity-precondition summaries as branch-local replay
provenance. CandidateRefresh accepts direct/list-valued, accepted-state,
mission-state, and wrapped `source_timeline_activity_precondition_summary` /
`timeline_activity_precondition_summary` artifacts, plus the same embedded
source summaries preserved through operator-review packages and
Cadence-import manifests. The replay summary preserves source paths,
model/schema identity, precondition status counts, blocked/review
precondition counts and type maps, dependency and exclusivity ID maps,
`allow_overlap`, invalid-input counts and reasons, activity/timeline routing,
trust-boundary evidence, and explicit no-mutation/no-authority assumptions.
`CandidateRefresh.source_report_summary/1` also exposes the same precondition
contract, source-count, source-row-count, source-path, status, count, type,
dependency, exclusivity, overlap, invalid-input, and activity/timeline routing
maps as `source_report_timeline_activity_precondition_*` top-level rollups for
compact consumers that do not inspect the nested `source_reports` block. The
top-level source-count, source-row-count, and source-path rollups require a
complete precondition source-report identity (`count` and `row_count` present);
partial placeholders only expose the declared contract. The helper does not
evaluate preconditions, select
candidates, approve imports, reserve resources, execute commands, write to
Cadence, or regenerate candidates. OperatorReview and CadenceImport lift the
same direct/list-valued, accepted-state, mission-state, and wrapped summaries
into `timeline_activity_precondition_review` /
`review_timeline_precondition` handoffs while preserving
`candidate_refresh.*` source paths, dependency/exclusivity evidence,
invalid-input evidence, and embedded source summaries without granting operator
authority or evaluating preconditions.
When the branch carries a non-empty
`candidate_source.candidate_refresh_request_source_report_summary.source_reports.timeline_activity_precondition_summary`
family, the replay helper labels its output source and replay scope as
candidate-source summary metadata, treats partial non-empty branch families as
authoritative, and falls back to provenance labels only when that branch family
is absent or empty.
The status-only and approval-only handoffs are also available as
contract-scoped replay summaries through
`CandidateRefresh.timeline_activity_status_state_replay_summary/1`,
`CandidateRefresh.timeline_activity_approval_state_replay_summary/1`, and their
matching `OrbitalDynamics.candidate_refresh_*` facades. Those summaries filter
the shared single-activity state provenance to
`timeline_activity_status_state.v1` or
`timeline_activity_approval_state.v1`, preserving source paths,
model/schema counts, transition decisions, required operator/import actions,
activity/timeline routing, invalid-input counts and reasons,
trust-boundary evidence, and branch-local pressure booleans without applying
status or approval changes. The aggregate
`CandidateRefresh.source_report_summary/1` surface also flattens those
contract-scoped status-state and approval-state source counts, paths,
transition/action/import count maps, and action-routing maps so adapters can
route the single-state replay evidence without reopening nested
`source_reports.timeline_activity_state` payloads.
When a branch `timeline_activity_state` source-report family is non-empty and
matches the requested `timeline_activity_status_state.v1` or
`timeline_activity_approval_state.v1` contract, these contract-scoped helpers
label their output source and replay scope as candidate-source summary metadata,
treat partial non-empty branch families as authoritative, and fall back to
provenance labels for absent, empty, or contract-mismatched branch families.
`CandidateRefresh.timeline_activity_state_replay_summary/1` and its matching
`OrbitalDynamics` facade prefer a non-empty V3
`candidate_source.candidate_refresh_request_source_report_summary.source_reports.timeline_activity_state`
family over provenance, label their output source and replay scope as
candidate-source summary metadata, and treat partial non-empty branch families
as authoritative while preserving provenance fallback for absent or empty branch
families.
`CandidateRefresh.source_report_summary/1` also flattens
`source_report_timeline_activity_state_count`, `row_count`, and `paths`, plus a
single `contract` when the family summary declares one, for compact consumers;
partial activity-state source-report family placeholders can preserve the
declared contract, but omit flattened count, row-count, and path fields until
both identity counts are present.
CandidateRefresh review/import handoff also accepts direct/list-valued,
accepted-state, mission-state, and wrapped
`source_timeline_preservation_report` /
`timeline_preservation_report` and `source_timeline_preservation_status` /
`timeline_preservation_status` artifacts. Those inputs lift lock, approved,
executed, invalid-input, preservation-required, and review-required evidence
into `timeline_preservation_review` / `review_timeline_preservation` rows while
preserving `candidate_refresh.*` source paths and the artifact-only
no-schedule-mutation/no-operator-authority/no-Cadence-write boundary.
`CandidateRefresh.timeline_preservation_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_timeline_preservation_replay_summary/1`
summarize that same preservation provenance as branch-local replay evidence.
The summary keeps direct, canonical, and wrapped report/status source paths,
`timeline_preservation_report.v1` versus `timeline_preservation_status.v1`
counts, preservation-status and required-action maps, protection
decision/category/reason maps, activity/timeline routing, trust-boundary
evidence, and no-mutation/no-authority assumptions without recording
preservation, approving imports, mutating timelines, executing commands, or
writing to Cadence.
When a V3 branch carries the `candidate_refresh_request_source_report_summary`
marker and non-empty `candidate_source` preservation report/status rows, the
replay helper labels its output source and replay scope as candidate-source
request metadata, rewrites row source paths to the
`candidate_source.candidate_refresh_request.*` boundary, treats partial branch
rows as authoritative, and falls back to review-provenance labels when branch
preservation rows are absent, empty, or unmarked.

`CandidateRefresh.timeline_dependency_impact_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_timeline_dependency_impact_replay_summary/1`
expose timeline dependency-impact summaries as branch-local replay provenance.
The helper accepts direct `timeline_dependency_impact_summary` inputs, exact
`source_result_artifact` / `result_artifact` dependency-impact summaries,
wrapped `source_timeline_dependency_impact_summary` /
`timeline_dependency_impact_summary` result-artifact inputs, and the same rows
preserved through operator-review packages or Cadence-import manifests,
preserving top-level source-report contract/count/row-count/path rollups,
source/replacement scope counts, impacted source, dependency, and exclusivity
ID maps, dependent activity/timeline routing, trust boundaries, and
operator-review pressure without mutating timelines, selecting candidates,
approving imports, writing to Cadence, or regenerating candidates. Compact
top-level dependency-impact source-count, source-row-count, and source-path
rollups require complete source-report identity (`count` and `row_count`
present); partial placeholders only expose the declared contract.
Generated V3 branch refresh requests preserve the same source/dependency/
exclusivity and dependent activity/timeline ID maps through branch-local
candidate-source provenance.
When dependency-impact provenance is absent, the replay summary omits the
contract field rather than defaulting to
`timeline_dependency_impact_summary.v1`. Capability metadata advertises
`timeline_dependency_impact_summary` as an accepted CandidateRefresh input
alongside timeline dependency-impact replay provenance.
`CandidateRefresh.timeline_publication_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_timeline_publication_replay_summary/1`
expose timeline publication summaries as branch-local replay provenance. The
helper accepts direct `timeline_publication_summary` /
`source_timeline_publication_summary` inputs, exact `source_result_artifact` /
`result_artifact` publication summaries, wrapped publication-summary fields,
and publication rows preserved through operator-review packages or
Cadence-import manifests. Replay preserves source-report contract/count/
row-count/path rollups, publication ID/status/authority, source artifact IDs
and types, superseded and downstream product IDs, invalidated downstream IDs,
explicit downstream invalidation status counts, dependency-impact
status/count/ID evidence, changed-field audit counts and
timeline routing, trust boundaries, and branch-local dependency, changed-field,
invalidation, review, and publication pressure booleans. It never publishes,
delivers notifications, mutates timelines, selects candidates, approves
imports, writes to Cadence, or regenerates candidates. Candidate-source
`candidate_refresh_request_source_report_summary` metadata is authoritative
when present; when publication provenance is absent, the replay summary omits
the contract field rather than defaulting to
`timeline_publication_summary.v1`.

`OperatorReview.from_candidate_refresh_artifact/1` lifts review-required
direct/list-valued `source_contact_intent`, `source_contact_intents`, and
singular `contact_intent` inputs into `contact_intent_review` rows with
`candidate_refresh.*` source paths. Top-level refresh `contact_intents` keep
their existing `candidate_refresh.contact_intents` path, so source-report
handoffs remain deterministic without duplicating the primary refresh-intent
surface. The handoff also unpacks contact-intent review evidence from
direct/list-valued `source_operator_review_package`,
`source_cadence_import_manifest`, and nested `source_result_artifact` /
`result_artifact` contact-intent containers, preserving container-qualified
source paths such as `*.rows.source_contact_intent[0]`.
Direct/list-valued, canonical, exact result-artifact, and nested
result-artifact-wrapped `source_contact_intent_summary` /
`contact_intent_summary` inputs synthesize direction-scoped
`contact_intent_review` rows from compact summary station, direction, contact,
and capacity-demand maps. `CadenceImport.from_candidate_refresh_artifact/1`
carries those rows as `review_contact_intent` import rows, preserving
summary-qualified `candidate_refresh.*.summary_contacts` source paths,
all-contact direction routing, capacity-pack contact IDs, required-capacity
fraction evidence, source-summary model/contract/artifact-type identity,
assumptions, and source-review-row evidence without generating contacts,
allocating station time, selecting candidates, approving imports, writing to
Cadence, or mutating schedules.
Capability metadata advertises `contact_intents` as an accepted CandidateRefresh
input alongside generated contact-intent outputs and source-report replay
provenance.

`CandidateRefresh.timeline_transition_application_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_timeline_transition_application_replay_summary/1`
expose the timeline-transition-application slice as a branch-local replay
summary. It preserves top-level source-report contract/count/row-count/path rollups,
source application paths, application/selected/review/preserved/replacement/
withheld counts, selected-activity ID maps, selected-subset timeline-integrity
review/issue counts and issue-type counts, status/decision/action maps,
duplicate identity counts/maps, trust-boundary evidence, and branch-local
application, selection, selected-integrity, review, preservation,
duplicate-identity, and operator-review pressure booleans without applying
timeline transitions, mutating timelines, selecting candidates, approving
imports, writing to Cadence, or regenerating candidates. The family-level
timeline-transition-application pressure boolean is true for selected-activity
evidence even when application/status/decision maps are absent. Application counts,
duplicate identity counts, selected-activity ID maps, selected-integrity counts,
and status/decision/action/scope maps are derived from application or selected
activity rows when rows are present instead of trusted from stale top-level
transition aggregates.
Selected, review-required, preserved-source, recorded-replacement, and
withheld-review counts follow the same row-first rule.
The family-level transition-application pressure boolean is also true for
preserved review/action, preserved-source/replacement, and duplicate-identity
evidence even when aggregate application/status/decision/selected-activity
inputs are absent or zero.
When timeline-transition-application provenance is absent, the replay summary
omits the contract field rather than defaulting to
`timeline_transition_application_report.v1`.
Partial timeline-transition-application source-report family placeholders can
preserve the declared contract, but omit flattened count, row-count, and path
fields until both identity counts are present.
The same replay family accepts direct, accepted-state, mission-state, exact
`source_result_artifact` / `result_artifact`, and wrapped
`source_timeline_transition_application_summary` /
`timeline_transition_application_summary` inputs, preserving the compact
`timeline_transition_application_summary.v1` contract, selected activity IDs,
review activity IDs, review/withheld/preserved counts, status/decision/action
maps, source paths, and trust-boundary evidence without expanding the summary
into an applied transition or mutating timelines.
`OperatorReview.from_candidate_refresh_artifact/1` and
`CadenceImport.from_candidate_refresh_artifact/1` also lift direct,
accepted-state, mission-state, and wrapped
`source_timeline_transition_application_report` /
`timeline_transition_application_report` applications plus compact
`source_timeline_transition_application_summary` /
`timeline_transition_application_summary` review applications into
`timeline_diff_review` / review-import rows with `candidate_refresh.*` source
paths. This preserves application context for review without applying
transitions or mutating timelines.
The replay helper can inspect V3 branch `candidate_source` metadata that carries
`candidate_refresh_request_source_report_summary`, so strategy-derived branch
refreshes preserve transition-application selection/review/duplicate pressure
through the branch provenance boundary.
Branch-generated refresh requests also preserve direct and
`source_result_artifact` / `result_artifact` wrapped
`source_timeline_transition_application_report` /
`timeline_transition_application_report` inputs, plus compact
`source_timeline_transition_application_summary` /
`timeline_transition_application_summary` inputs, with wrapper-qualified request
paths, row-derived selected/review activity routing and duplicate evidence,
status/decision/action maps, and direct plus inherited trust-boundary evidence.
Capability metadata advertises `timeline_transition_application_report` and
`timeline_transition_application_summary` as accepted CandidateRefresh inputs
alongside timeline-transition-application replay provenance.

`CandidateRefresh.objective_gap_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_objective_gap_replay_summary/1` expose the
objective-gap slice as a branch-local replay summary across
objective-satisfaction, objective-tradeoff, and score-term provenance. It
preserves top-level source-report contracts/count/path rollups, source paths,
routed downlink/target/collection-latency gap counts, objective status/type
maps, score-term key maps, station/target/collection and source-activity ID
routing maps, trust-boundary evidence, and branch-local objective-gap,
downlink, target, collection-latency, status, score-term, and routing pressure
booleans without creating objectives, recalculating scores, selecting
candidates, approving imports, writing to Cadence, or regenerating candidates.
The source-report summary exposes the same aggregate objective-gap signal count
and combined station/target/collection/source-activity routing maps so
branch-local consumers do not need to recompute cross-family objective pressure
from per-family fields. Compact aggregate objective-gap count/row-count/path
rollups require complete source-report identity (`count` and `row_count`
present) for each contributing source family, so partial placeholders preserve
declared contracts and routed pressure evidence without implying complete
aggregate identity. These maps are derived from objective/score rows before stale
top-level source-activity aggregates. The family-level objective-gap pressure
boolean is true for objective status/type, score-term key, or routing evidence
even when routed gap counts are absent.
`OperatorReview.from_candidate_refresh_artifact/1` also lifts direct
`source_objective_satisfaction_report` and `objective_satisfaction_report`
non-passing rows, plus objective-satisfaction reports preserved in
`source_result_artifact` / `result_artifact` wrappers, into
`objective_satisfaction_review` rows with `candidate_refresh.*` source paths.
This preserves objective-review pressure without creating objectives,
recalculating scores, or selecting candidates.
It also lifts direct `source_objective_tradeoff_report` and
`objective_tradeoff_report` rows, plus objective-tradeoff reports preserved in
`source_result_artifact` / `result_artifact` wrappers, into
`objective_tradeoff_review` rows with `candidate_refresh.*` source paths,
preserving tradeoff review pressure without recalculating scores or selecting
candidates.
It also lifts direct `source_score_term_report` and `score_term_report` rows,
plus score-term reports preserved in `source_result_artifact` /
`result_artifact` wrappers, into `score_term_review` rows with
`candidate_refresh.*` source paths, preserving score-term review pressure
without recalculating scores or selecting candidates.
The replay helper can inspect V3 branch `candidate_source` metadata that carries
`candidate_refresh_request_source_report_summary`, so strategy-derived branch
refreshes preserve objective-gap downlink/target/latency/score/activity-routing
pressure through the branch provenance boundary.
Branch-generated refresh requests also preserve mission-state
`source_result_artifact` / `result_artifact` wrapped
`source_objective_satisfaction_report` and `objective_satisfaction_report`
inputs with wrapper-qualified request paths, indexed embedded replay copies,
objective status/type and downlink routing summaries, and inherited
trust-boundary evidence.
They also preserve mission-state result-artifact-wrapped
`source_objective_tradeoff_report` and `objective_tradeoff_report` inputs with
wrapper-qualified request paths, indexed embedded replay copies, tradeoff
downlink/collection-latency routing summaries, and inherited trust-boundary
evidence.
They also preserve mission-state result-artifact-wrapped
`source_score_term_report` and `score_term_report` inputs with
wrapper-qualified request paths, indexed embedded replay copies, score-term key
and downlink routing summaries, and inherited trust-boundary evidence.
Its contract list is derived only from source-report families that are actually
present, so a score-term-only replay summary does not imply objective-
satisfaction or tradeoff provenance.
Capability metadata advertises `objective_satisfaction_report`,
`objective_tradeoff_report`, and `score_term_report` as accepted
CandidateRefresh inputs alongside objective-gap replay provenance.

`CandidateRefresh.constraint_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_constraint_replay_summary/1` expose the
constraint slice as a branch-local replay summary. It preserves source
constraint paths, top-level source-report contract/count/path rollups, row
counts, downlink-gap and resource-margin counts, status maps, constraint-ID
maps, source-activity ID maps,
station/metric/resource/spacecraft routing maps, trust-boundary evidence, and
branch-local constraint, downlink-gap, resource-margin, and routing pressure
booleans without creating objectives, mutating resource state, selecting
candidates, approving imports, writing to Cadence, or regenerating candidates.
Constraint-ID and source-activity ID maps are derived from rows when rows are
present, so stale top-level constraint aggregates cannot steer branch-local
constraint routing. The family-level constraint pressure boolean is true for
routing-only evidence even when downlink/resource row counts and status maps are
absent.
`OperatorReview.from_candidate_refresh_artifact/1` also lifts direct
`source_constraint_report` and `constraint_report` non-passing rows, plus
constraint reports preserved in `source_result_artifact` / `result_artifact`
wrappers, into `constraint_review` rows with `candidate_refresh.*` source paths.
This preserves constraint-review pressure without creating objectives or
mutating resource state.
The replay helper can inspect V3 branch `candidate_source` metadata that carries
`candidate_refresh_request_source_report_summary`, so strategy-derived branch
refreshes preserve constraint downlink/resource/routing pressure through the
branch provenance boundary.
Branch-generated refresh requests also preserve mission-state
`source_result_artifact` / `result_artifact` wrapped `source_constraint_report`
and `constraint_report` inputs with wrapper-qualified request paths, indexed
embedded replay copies, and inherited trust-boundary evidence.
When constraint provenance is absent, the replay summary omits the contract
field rather than defaulting to `constraint_report.v1`.
`CandidateRefresh.source_report_summary/1` also exposes compact top-level
constraint contract/count/row-count/path rollups for source-report provenance.
Compact constraint source-count/source-row-count and source-path fields require
complete source-report identity (`count` and `row_count` present), so partial
placeholders preserve only the declared contract while non-identity
constraint/routing rollups, explicit zero counts, and explicit empty paths
remain replayable evidence.
Capability metadata advertises `constraint_report` as an accepted
CandidateRefresh input alongside constraint replay provenance.

`CandidateRefresh.timeline_feedback_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_timeline_feedback_replay_summary/1` expose
the timeline-feedback slice as a branch-local replay summary. It preserves
source timeline-feedback paths, row counts, feedback input keys, status,
feedback-kind, match-strategy, activity-ID, Cadence-import-status,
station-reservation evidence counts, trust-boundary evidence, and branch-local
feedback, input, activity-routing, match-review, import-review, and
station-reservation pressure booleans without applying operational feedback,
mutating timelines, selecting candidates, approving imports, writing to
Cadence, or regenerating candidates. `CandidateRefresh.source_report_summary/1`
also exposes compact top-level timeline-feedback contract/count/row-count/path
rollups; those compact source-count, source-row-count, and source-path fields
require complete source-report identity (`count` and `row_count` present), while
partial placeholders only expose the declared contract. The replay summary
itself still treats partial non-empty branch families as authoritative
provenance. The family-level timeline-feedback pressure boolean is true for
station-reservation evidence even when no operational feedback input, activity,
status, or import-review map is present, and is also true for match-strategy-only
evidence. Status, feedback-kind, match-strategy, and
activity-ID maps, plus Cadence-import-status maps, are derived from
timeline-feedback rows instead of trusted from stale top-level report aggregate
maps.
Operational-feedback provenance for source timeline-feedback reports applies
the same row-first boundary for status, feedback-kind, match-strategy,
activity-ID, and Cadence-import status maps.
Operator-review packages built from candidate-refresh artifacts also lift
direct `source_timeline_feedback_report` / `timeline_feedback_report` rows into
`realized_feedback` review rows, and lift timeline-feedback reports preserved
as exact `source_result_artifact` / `result_artifact` maps or nested inside
result-artifact wrapper fields into the same row family. CandidateRefresh
source-report replay preserves those exact and wrapped result-artifact paths,
match context, realized provenance, and station-reservation evidence without
applying feedback or approving imports.
The replay helper can inspect V3 branch `candidate_source` metadata that carries
`candidate_refresh_request_source_report_summary`, so strategy-derived branch
refreshes preserve timeline-feedback input, activity-routing, match,
station-reservation, and trust-boundary pressure through the branch provenance
boundary.
When the V3 branch carries a non-empty
`candidate_source.candidate_refresh_request_source_report_summary.source_reports.timeline_feedback_report`
family, the replay helper labels its output source and replay scope as
candidate-source summary metadata, treats partial non-empty branch families as
authoritative, and falls back to provenance labels only when that branch family
is absent or empty.
When timeline-feedback provenance is absent, the replay summary omits the
contract field rather than defaulting to `timeline_feedback_report.v1`.

`CandidateRefresh.operational_timeline_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_operational_timeline_replay_summary/1`
expose the operational-timeline slice as a branch-local replay summary. It
preserves source operational-timeline paths, row counts,
contact/command/maneuver/observation/station-throughput feedback counts,
integrity issue counts, row-derived operational-kind, activity-ID, activity-status,
approval-status, required-action, Cadence-import-status, and integrity-issue-type maps,
station-reservation evidence counts, input keys, trust-boundary evidence, and
branch-local operational-timeline, feedback, activity-routing, integrity, and
station-reservation pressure booleans without applying operational feedback,
mutating timelines, selecting candidates, approving imports, writing to Cadence,
or regenerating candidates. `CandidateRefresh.source_report_summary/1` also
exposes compact top-level operational-timeline contract/count/row-count/path
rollups; those compact source-count, source-row-count, and source-path fields
require complete source-report identity (`count` and `row_count` present), while
partial placeholders only expose the declared contract. The replay summary
itself still treats partial non-empty branch families as authoritative
provenance. The family-level operational-timeline pressure boolean is true for
station-reservation evidence even when no operational feedback input, activity,
status, import-review, or integrity map is present. It is also true for
operational-kind, activity-status, approval-status, required-action,
Cadence-import-status, or integrity-issue-type maps even when feedback,
activity-routing, integrity-count, and station-reservation counters are absent.
These maps and integrity counts are derived from rows rather than trusted from
stale top-level report aggregates.
Operational-feedback provenance for operational-timeline, timeline-diff,
command-window, and maneuver-review source reports uses a shared compact replay
boundary for derived flags, paths, counts, trust-boundary evidence, row-derived
maps, and deterministic input-key merging.
The replay helper can inspect V3 branch `candidate_source` metadata that carries
`candidate_refresh_request_source_report_summary`, so strategy-derived branch
refreshes preserve operational-timeline feedback, row-derived action/import
maps, activity-routing, trust-boundary, and branch-local pressure through the
branch provenance boundary.
When the V3 branch carries a non-empty
`candidate_source.candidate_refresh_request_source_report_summary.source_reports.operational_timeline_report`
family, the replay helper labels its output source and replay scope as
candidate-source summary metadata, treats partial non-empty branch families as
authoritative, and falls back to provenance labels only when that branch family
is absent or empty.
Candidate-refresh operator-review packages also lift direct
`source_operational_timeline_report` / `operational_timeline_report` rows and
operational-timeline reports preserved as exact `source_result_artifact` /
`result_artifact` maps or nested inside result-artifact wrapper fields into
`operational_timeline_review` rows. Source-report replay preserves those exact
and wrapped result-artifact paths and source row payloads without applying
operational feedback or mutating timelines.
When operational-timeline provenance is absent, the replay summary omits the
contract field rather than defaulting to `operational_timeline_report.v1`.

`CandidateRefresh.quality_gate_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_quality_gate_replay_summary/1` expose the
quality-gate slice of that provenance as a branch-local replay summary. It
preserves top-level source-report contract/count/path rollups, source
quality-gate paths, readiness/import/status maps, gate status/classification
maps, status-grouped and classification-grouped gate and quality-gate row ID
maps, per-status and non-passed gate ID lists, non-passed quality-gate row ID
lists, analysis-mode counts,
import/freshness/schema-validation count maps, resource-availability reason
maps including station-specific availability reason counts, resource-blocking
dimension maps, source-readiness report counts, and timeline-publication context
from quality-gate rows and compact operational quality-gate import-readiness
summaries: publication status, authority, timeline-publication source-artifact
type counts, source/publication/downstream IDs, dependency-impact rows and IDs,
timeline-diff changed/review counts, changed field maps, changed/review timeline
IDs, and changed-field timeline routing. It also exposes review/import/resource
pressure booleans and branch-local timeline-publication pressure,
dependency-pressure, changed-field-pressure, invalidation-pressure, and
review-pressure booleans. The replay-summary helper itself avoids candidate
generation, candidate selection, Cadence writes, and operator approval; the
separate CandidateRefresh build path applies only exact candidate-scoped
blocked planned-activity quality-gate/readiness reports or exact spacecraft-
scoped blocked-contact evidence from canonical readiness reports or
unavailable-resource quality summaries as documented above. Review
pressure is true for preserved
readiness/status/gate status, classification, and analysis-mode maps; import
pressure is true for preserved import-status and Cadence-import-status maps
even when aggregate review/import counters are absent or zero. Resource pressure
is true for resource/station availability reason maps, reason ID sets,
unavailable-resource IDs, and blocking-dimension maps even when the aggregate
resource-availability pressure count is absent or zero.
CandidateRefresh also accepts direct
`source_operational_quality_gate_import_readiness_summary` /
`operational_quality_gate_import_readiness_summary` inputs and the same
summaries nested in `source_result_artifact` / `result_artifact` wrappers. These
compact `operational_quality_gate_import_readiness_summary.v1` inputs replay
through the `quality_gate_report` provenance family with wrapper-qualified
paths, inherited trust-boundary evidence, source-summary model/schema/source
artifact counts, freshness/import/Cadence-import/schema-validation maps, gate
row ID maps, freshness/import/Cadence-import status IDs, schema-validation
status IDs, and import-readiness gate IDs preserved. They remain artifact-only:
they do not certify gates, approve imports, write to Cadence, or regenerate
candidates.
The replay helper can inspect V3 branch `candidate_source` metadata that carries
`candidate_refresh_request_source_report_summary`, so strategy-derived branch
refreshes preserve quality-gate review/import/resource pressure through the
branch provenance boundary.
Branch-generated refresh requests preserve direct and result-artifact-wrapped
quality-gate reports with wrapper-qualified request input paths and indexed
embedded replay copies.
Candidate-refresh operator-review packages also lift direct
`source_quality_gate_report` / `quality_gate_report` rows into
`quality_gate_review` rows, preserving source paths, source row/report payloads,
and resource reason context without certifying gates or approving imports.
Quality-gate reports wrapped in direct/list-valued `source_result_artifact` /
`result_artifact` containers are lifted into the same review-row family with
wrapper-qualified `candidate_refresh.*.quality_gate_report.rows` source paths.
When quality-gate provenance is absent, the replay summary omits the contract
field rather than defaulting to `quality_gate_report.v1`.
`CandidateRefresh.source_report_summary/1` also exposes compact top-level
quality-gate contract/count/row-count/path rollups for source-report
provenance. Compact quality-gate source-count/source-row-count and source-path
fields require complete source-report identity (`count` and `row_count`
present), so partial placeholders preserve only the declared contract while
non-identity review/import/resource rollups, explicit zero counts, and explicit
empty paths remain replayable evidence.
When raw quality-gate provenance carries `quality_gate_row_ids_by_status`, that
status map drives flattened and replayed review-required, blocked, ready, and
analysis-only row-ID arrays before any duplicated top-level routing arrays.

`CandidateRefresh.model_acceptance_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_model_acceptance_replay_summary/1` expose the
model-acceptance slice as a branch-local replay summary. It preserves source
contract, count, row-count, source paths, validation-record/model counts, status
and intended-use maps, validation-level maps, model-ID routing maps,
trust-boundary evidence, and review/blocking/unknown-model pressure booleans
without certifying models,
approving imports, writing to Cadence, or regenerating candidates. Review,
blocking, and unknown-model pressure are true for status maps and model-ID
routing maps even when the aggregate review, blocked, or unknown-model counters
are absent or zero.
`CandidateRefresh.source_report_summary/1` also exposes compact top-level
model-acceptance contract/count/row-count/path rollups for source-report
provenance. Compact model-acceptance source-count/source-row-count and
source-path fields require complete source-report identity (`count` and
`row_count` present), so partial placeholders preserve only the declared
contract while non-identity model-status/routing rollups, explicit zero counts,
and explicit empty paths remain replayable evidence.
The replay helper can inspect V3 branch `candidate_source` metadata that carries
`candidate_refresh_request_source_report_summary`, so strategy-derived branch
refreshes preserve model-acceptance review/blocking/unknown-model pressure
through the branch provenance boundary.
Branch-generated refresh requests preserve direct and result-artifact-wrapped
model-acceptance reports with wrapper-qualified request input paths and indexed
embedded replay copies.
Candidate-refresh operator-review packages also lift model-acceptance reports
wrapped in direct/list-valued `source_result_artifact` / `result_artifact`
containers into `model_acceptance_review` rows with wrapper-qualified
`candidate_refresh.*.model_acceptance_report.rows` source paths, preserving
row-level model status and report-level count context without certifying models.
When model-acceptance provenance is absent, the replay summary omits the
contract field rather than defaulting to `model_acceptance_report.v1`, and the
aggregate source-report summary omits the top-level model-acceptance identity
rollups instead of emitting empty contract/count/row-count/path fields.

`CandidateRefresh.validation_safety_case_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_validation_safety_case_replay_summary/1`
expose the validation-safety-case slice as a branch-local replay summary. It
preserves contract, count, row-count, source paths, evidence status maps,
input-contract maps, evidence-reference maps,
model/readiness/quality-gate/schema/fixture counters, trust-boundary evidence,
and review/blocking/schema/fixture pressure booleans without certifying safety
cases or models, approving imports, writing to Cadence, or regenerating
candidates. When evidence rows are present, evidence status maps are derived
from those rows rather than stale top-level
`evidence_status_counts` aggregates. Review and blocking pressure are true for
status maps and evidence-reference maps, while schema and fixture pressure are
true for schema/fixture input-contract or evidence-reference routing maps even
when the aggregate schema or fixture counters are absent or zero.
The replay helper can inspect V3 branch `candidate_source` metadata that carries
`candidate_refresh_request_source_report_summary`, so strategy-derived branch
refreshes preserve validation-safety-case evidence/review/blocking/schema
pressure through the branch provenance boundary.
Branch-generated refresh requests preserve direct and `source_result_artifact` /
`result_artifact`-wrapped `source_validation_safety_case_summary` /
`validation_safety_case_summary` inputs with wrapper-qualified source paths,
evidence maps, and inherited trust-boundary evidence; replay remains
artifact-only and does not certify safety cases, approve imports, write to
Cadence, or regenerate candidates.
When validation-safety-case provenance is absent, the replay summary omits the
contract field rather than defaulting to `validation_safety_case_summary.v1`,
and the aggregate source-report summary omits the top-level
validation-safety-case count, row-count, and path identity rollups instead of
emitting empty identity fields. Empty or partial placeholder provenance can
still preserve a declared contract, but does not synthesize count, row-count, or
path identity rollups unless both identity counts are present. Explicit zero
count and row-count values are preserved as declared identity, paths remain
omitted when the path field is missing or nil, and an explicit empty path list
remains a declared empty path set. Non-identity evidence status,
input-contract, and evidence-reference maps remain available to branch-local
replay pressure even when the source-report identity is only partial.
Operator-review packages built from candidate-refresh artifacts also lift
direct `source_validation_safety_case_summary` /
`validation_safety_case_summary` evidence rows that are review-required or
blocked into `validation_safety_case_review` rows. The handoff preserves
indexed `candidate_refresh.*.evidence` source paths, evidence refs, input
contracts, source evidence payloads, and summary-level count context without
certifying safety cases, accepting models, or approving imports.
Validation-safety summaries wrapped in direct/list-valued
`source_result_artifact` / `result_artifact` containers are lifted into the
same review-row family with wrapper-qualified
`candidate_refresh.*.validation_safety_case_summary.evidence` source paths.

`CandidateRefresh.freshness_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_freshness_replay_summary/1` expose the
freshness slice as a branch-local replay summary. It preserves source freshness
contract, count, row-count, source paths, stale/unknown status maps,
stale/unknown reason lists/count maps, trust-boundary evidence, and branch-local
stale/unknown pressure booleans
without mutating refresh state, approving imports, writing to Cadence, or
regenerating candidates. `CandidateRefresh.source_report_summary/1` also
exposes compact top-level freshness contract/count/row-count/path rollups; those
compact source-count, source-row-count, and source-path fields require complete
source-report identity (`count` and `row_count` present), while partial
placeholders only expose the declared contract. Stale/unknown pressure is true
for reason lists and reason-count maps even when the aggregate reason counters
are absent or zero.
The replay helper can inspect V3 branch `candidate_source` metadata that carries
`candidate_refresh_request_source_report_summary`, so
strategy-derived branch refreshes preserve freshness status and stale/unknown
pressure routing through the branch provenance boundary.
Branch-generated refresh requests preserve direct and result-artifact-wrapped
mission-state freshness reports with wrapper-qualified request input paths and
indexed embedded replay copies, so stale/unknown pressure remains visible to
`CandidateRefresh.freshness_replay_summary/1`.
`OperatorReview.from_candidate_refresh_artifact/1` also lifts direct
`source_freshness_report` and `freshness_report` stale/unknown summaries into
`freshness_review` rows with `candidate_refresh.*` source paths. This preserves
freshness review pressure without mutating refresh state, approving imports,
writing to Cadence, or regenerating candidates.
The same operator-review handoff accepts freshness reports inside
candidate-refresh `source_result_artifact` / `result_artifact` wrappers,
preserving wrapper-qualified source paths and list indexes.
When freshness provenance is absent, the replay summary omits the contract
field rather than defaulting to `freshness_report.v1`, and the aggregate
source-report summary omits the top-level freshness identity rollups instead of
emitting empty contract/count/row-count/path fields.
Capability metadata advertises `freshness_report` as an accepted CandidateRefresh
input alongside freshness replay provenance.

`CandidateRefresh.refresh_budget_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_refresh_budget_replay_summary/1` expose the
refresh-budget slice as a branch-local replay summary. It preserves source
budget contract, count, row-count, source paths, input/kept/dropped candidate
counts, invalid-limit reason maps, kept/dropped candidate IDs, trust-boundary
evidence, and branch-local budget pressure booleans without mutating refresh
state, approving imports, writing to Cadence, or regenerating candidates.
Budget/drop/invalid-limit pressure is true for invalid-limit reason maps and
kept/dropped candidate ID sets even when the aggregate dropped-candidate or
invalid-limit counters are absent or zero. The family-level budget pressure
boolean is also true when preserved input/kept counts show a candidate limit was
applied, even if dropped-candidate and invalid-limit evidence is absent or zero.
The replay helper can inspect V3
branch `candidate_source` metadata that carries
`candidate_refresh_request_source_report_summary`, so strategy-derived branch
refreshes preserve refresh-budget counts and limit-pressure routing through the
branch provenance boundary.
Branch-generated refresh requests preserve direct and result-artifact-wrapped
mission-state refresh-budget reports with wrapper-qualified request input paths
and indexed embedded replay copies, so input/kept/dropped counts,
invalid-limit evidence, and kept/dropped candidate IDs remain visible to
`CandidateRefresh.refresh_budget_replay_summary/1`.
`OperatorReview.from_candidate_refresh_artifact/1` also lifts direct
`source_refresh_budget_report` and `refresh_budget_report` dropped-candidate or
invalid-limit summaries into `refresh_budget_review` rows with
`candidate_refresh.*` source paths. This preserves budget review pressure
without mutating refresh state, approving imports, writing to Cadence, or
regenerating candidates.
The same operator-review handoff accepts refresh-budget reports inside
candidate-refresh `source_result_artifact` / `result_artifact` wrappers,
preserving wrapper-qualified source paths and list indexes.
When refresh-budget provenance is absent, the replay summary omits the contract
field rather than defaulting to `refresh_budget_report.v1`, and the aggregate
source-report summary omits the top-level refresh-budget identity rollups
instead of emitting empty contract/count/row-count/path fields.
`CandidateRefresh.source_report_summary/1` also exposes compact top-level
refresh-budget contract/count/row-count/path rollups for source-report
provenance. Compact refresh-budget source-count/source-row-count/source-path
fields require complete source-report identity (`count` and `row_count`
present), so partial placeholders preserve only the declared contract while
explicit zero counts and explicit empty paths remain replayable identity.
Capability metadata advertises `refresh_budget_report` as an accepted
CandidateRefresh input alongside refresh-budget replay provenance.

`CandidateRefresh.schema_validation_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_schema_validation_replay_summary/1` expose
the schema-validation slice as a branch-local replay summary. It preserves
source validation contract, count, row-count, paths, status/contract/mode maps,
error and warning counts, remediation action/category/path maps,
trust-boundary evidence, and branch-local validation pressure booleans without
mutating refresh state, approving imports, writing to Cadence, or regenerating
candidates. Validation pressure is true for preserved status,
validated-contract, or validation-mode maps, and error, warning, and
remediation pressure are true for status maps and remediation routing maps even
when the aggregate error, warning, or remediation counters are absent or zero.
The replay helper can inspect V3 branch `candidate_source` metadata that carries
`candidate_refresh_request_source_report_summary`, so strategy-derived branch
refreshes preserve schema-validation status, error, and remediation routing
through the branch provenance boundary. Branch-generated refresh requests also
preserve direct mission-state `source_schema_validation_report` /
`schema_validation_report` inputs plus `source_result_artifact` /
`result_artifact` wrapped report copies with wrapper-qualified request input
paths and indexed embedded replay copies. They also preserve direct
mission-state `source_schema_validation_batch_report` inputs and
`source_result_artifact` / `result_artifact` wrapped batch reports, flattening
nested `reports[*].report` entries while retaining inherited trust-boundary
evidence.
When schema-validation provenance is absent, the replay summary omits the
contract field rather than defaulting to `schema_validation_report.v1`, and the
aggregate source-report summary omits the top-level schema-validation count,
row-count, and path identity rollups instead of emitting empty identity fields.
Empty or partial placeholder provenance can still preserve a declared contract,
but does not synthesize count, row-count, or path identity rollups unless both
identity counts are present. Explicit zero count and row-count values are
preserved as declared identity, paths remain omitted when the path field is
missing or nil, and an explicit empty path list remains a declared empty path
set. Non-identity status, validated-contract, validation-mode, and remediation
routing maps remain available to branch-local replay pressure even when the
source-report identity is only partial.
Candidate-refresh operator-review packages also lift direct
`source_schema_validation_report` / `schema_validation_report` rows into
`schema_validation_review` rows, preserving source paths, validation issue
context, remediation context, and source report payloads without approving
imports or writing to Cadence. Schema-validation reports preserved in
direct/list-valued `source_operator_review_package`,
`source_cadence_import_manifest`, and nested `source_result_artifact` /
`result_artifact` containers are unpacked into the same review-row family with
container-qualified `*.rows.source_schema_validation_report` paths.
When schema-validation provenance is absent, the replay summary omits the
contract field rather than defaulting to `schema_validation_report.v1`, and the
aggregate source-report summary omits the top-level schema-validation identity
rollups instead of emitting empty contract/count/row-count/path fields. Partial
placeholder provenance does not synthesize count, row-count, or path identity
rollups unless both identity counts are present and non-nil.
Capability metadata advertises `schema_validation_report` and
`schema_validation_batch_report` as accepted CandidateRefresh inputs alongside
schema-validation replay provenance.

Capability metadata now advertises those source-report summary
contract/family/path, trust-boundary, status-count, candidate-diff,
readiness/quality-gate, branch-local candidate-diff, operational-readiness,
quality-gate, model-acceptance, validation-safety-case, freshness,
refresh-budget, and schema-validation replay, and resource-availability routing
semantics.

## Regression fixture

`study_results/candidate_refresh_resource_provenance_v1.json` is the checked-in
regression fixture for this path.

- It demonstrates mission-state readiness and quality-gate source reports with
  resource availability pressure summaries and derived station-specific
  availability reason ID/count-map fields preserved in
  `provenance.source_reports`; this fixture has no station-specific source
  reason, so those derived station fields are present as empty collections.
- Readiness and quality-gate summaries also preserve Cadence-import gate
  import-status, freshness, and schema-validation count maps, with quality-gate
  gate totals/status/classification derived from rows, so refresh provenance can
  route import eligibility without reopening the full readiness report.
- The fixture's product counts plus source-report family/row totals are pinned
  by the validation-reference fixture report.
- Curated candidate-scoped operational-readiness and quality-gate selection
  challenges pin the exact rejected observation and remaining contact,
  source-specific rejection label, planned-activity/report identity and path,
  blocked status, candidate selection scope, trust boundary, and respective
  `dropped_by_candidate_scoped_operational_readiness` /
  `dropped_by_candidate_scoped_quality_gate` invalidation reason. Stale
  identity/reason observations fail reference verification, and a valid report
  naming a different planned-activity ID produces no rejection.

**Schema validator checks:**

- The schema validator rejects malformed resource-context summary fields under
  `provenance.source_reports`, including non-string reason IDs and negative
  reason-count values; exported JSON Schemas expose those same nested summary
  fields.
- Generic source-report summary fields are checked too: `paths` must contain
  strings, and `count`/`row_count` must be non-negative integers.
- Validation-safety-case source summaries also reject negative evidence/count-map
  fields and non-string evidence-reference routing entries.

## Branch-generated refresh metadata

Repair- and strategy-generated refresh metadata preserves supplied source-report
paths for the following families: candidate-diff, candidate-rejection,
provider-counteroffer, station-calendar, station-reservation, contact-intent,
constraint, objective-satisfaction, objective-tradeoff, score-term, freshness,
refresh-budget, schema-validation, operational-readiness, quality-gate,
model-acceptance, and validation-safety-case. It also preserves normalized
provenance paths from nested result-artifact source reports.

These are carried in branch-generated `candidate_refresh.mission_state` bundles
and `candidate_source.source_report_input_paths`. Generated branches also expose
the request-derived subset in
`candidate_source.candidate_refresh_request_source_report_input_paths`, so
branch-local handoffs keep review/readiness provenance visible even before the
refresh artifact is inspected.
Mission-state operator-review and Cadence-import containers preserve replayable
contact-intent rows in that same request-derived subset as normalized
`rows.source_contact_intent[0]` paths while remaining artifact-only review
evidence.

## Stale-candidate detection

- Stale-candidate detection, `candidate_diff_report`, and `freshness_report`.

## Refresh ID stability

`refresh_id` stability holds over the material refresh inputs, including:

- accepted planning state
- mission-state objectives and spacecraft states
- target and ground-network declarations
- resource summaries
- prior candidates
- approval/resource/contact policies
- operational feedback

## Ground-network and station-ID alias normalization

- **Ground-network entries** — `ground_network` entries from study manifests may
  declare either `ground_station_id` or provider-shaped `station_id`. Campaign
  manifest metadata normalizes the alias to canonical `ground_station_id`, and
  campaign and candidate-refresh manifests preserve reservation metadata and
  provenance so downstream refresh, filtering, and calibration handling do not
  lose operator-supplied station context.
- **Mission-plan contact activities** — in study manifests these may also use
  `station_id` for downlink, tracking, command, and planned-contact station
  context. The loader normalizes that alias into canonical activity
  `ground_station_id` metadata before artifact generation.

## Prior candidate activities (manifest)

Candidate-refresh manifest `prior_candidate_activities` expose:

- provider-shaped `station_id`
- nested `station` / `ground_station` identity objects
- `start_s`, `end_s`
- canonical contact directions
- provider direction aliases

Normalization behavior:

- Rows with explicit downlink direction or no type/direction normalize into the
  same semantic candidate-diff path as runtime refresh requests.
- Direction-only command/uplink/tracking/health-check station windows keep their
  stale-candidate diff evidence.
- Command-result-shaped rows still require explicit command typing before import.

## Provider-calendar contention direction scope

Candidate refresh also infers provider-calendar contention direction scope from
embedded `source_station_calendar_entries` when a contention group omits a
group-level direction summary. This preserves uplink-only reservations without
suppressing refreshed downlink candidates.

## Model limits and assumptions

- Model limits and assumptions describing the thin event, resource, and contact
  models.

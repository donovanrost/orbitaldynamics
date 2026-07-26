# Compatibility Checks

Run the full checked-in schema export when contract surfaces change:

```bash
mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json
```

The exporter keeps common machine fields readable even when they rely on the
generic type fallback: scalar fields ending in `*_count` export as integers,
aggregate `*_counts` maps remain object-shaped summary maps, scalar `*_id`
fields export as stable-ID strings, and `*_ids` fields export as arrays of
stable-ID strings. Standalone contract schemas also keep explicit stable-ID
shapes for top-level identity fields whose semantics are enforced at runtime,
including `manifest_id`, `refresh_id`, validation `fixture_id` / `model_id`,
realized `planned_activity_id`, and contact-allocation invalid/blocked contact
ID arrays. Standalone contract schemas also embed the schema export
compatibility policy and stable public-ID policy under `x-orbital-dynamics`;
policy action-rule schemas and nested `policy_decision.v1` /
`approval_requirement.v1` rule-match schemas explicitly expose the same
scalar/plural policy-context vocabulary used by runtime rule matching,
including station-calendar, contact-allocation, timeline-protection, resource,
provenance, review-queue, and provider-result evidence arrays. Executable
campaign-strategy validation keeps full nested policy-decision count fields
derived from `rule_matches` when rule evidence is present, while legacy summary
branches without rule rows continue to mirror branch-level risk/approval counts.
the identity policy now names semantic generated-ID invariants such as
canonical source ordering before sequence suffix assignment for campaign and
candidate-refresh generated rows. Nested `$defs` keep the policy version
references without duplicating the full policy maps. The structural
`study_manifest.v1` schema exposes the same policy metadata for manifest
preflight tooling, and the generated manifest field reference carries the
policy version numbers so CLI consumers can detect which compatibility and
public-ID rules informed the reference. The exported identity policy and
`LinkCapacity.capabilities/0` also name the generated route-ID scope used by
`relay_data_path_summary.v1`: explicit route IDs take precedence, and fallback
IDs derive from semantic route evidence rather than source record order. The
reference exports and validates
`field_count` as a non-negative integer matching the emitted field rows, so
preflight tooling can detect truncated or duplicated field catalogs. The same
reference also publishes the supported manifest-lint error-code vocabulary under
`supported.lint_error_codes`,
including run-input preflight codes such as `missing_run_option` and
`invalid_run_option`, so import gates can route failures without parsing
free-text messages. The exported `study_manifest.v1` JSON Schema metadata names
the same combined semantic validator used by manifest lint:
`OrbitalDynamics.Study.Manifest.from_map/1 +
OrbitalDynamics.StudyRunner.validate_run_inputs/2`.

`campaign_strategy.v3` declares its complete produced top-level surface.
Source-repair identity, score-term, objective-tradeoff, Pareto-frontier,
operational-feedback provenance, and Cadence-import fields remain optional for
older artifacts; the four report fields embed their direct V1 contracts.
Executable validation applies those nested contracts at their strategy paths
and rejects stale feedback-provenance source counts, undeclared source
references, or input keys that no longer match the nonempty operational
feedback fields. The checked V3 strategy must have no top-level producer key
outside the generated schema property set.

Run artifact linting against the examples before treating a generated artifact
as a compatibility example:

```bash
mix orbital_dynamics.schema.lint --input study_results/leo_constellation_campaign.json
mix orbital_dynamics.schema.lint --input study_results/leo_constellation_campaign_strategy_v3.json --contract campaign_strategy.v3
mix orbital_dynamics.schema.lint --input study_results/leo_constellation_campaign.json --format json
mix orbital_dynamics.schema.lint --all --input-dir study_results
mix orbital_dynamics.manifest.lint --manifest studies/leo_constellation_campaign.json
mix orbital_dynamics.manifest.lint --manifest studies/leo_constellation_campaign.json --output study_results/study_manifest_lint_v1.json
mix orbital_dynamics.manifest.reference --output study_results/manifest_field_reference.json
mix orbital_dynamics.policy.export --bundle operator_review_queue_authority_v1 --output study_results/policy_bundle_operator_review_queue_authority_v1.json
mix orbital_dynamics.capabilities --format json
```

Manifest lint JSON reports declare the executable `study_manifest_lint.v1`
contract and preserve the subject manifest schema as `manifest_schema_contract:
study_manifest.v1`. The report contract validates `lint_task`, `error_count`,
and `warning_count` fields alongside stable error-code rows, giving preflight
automation count fields to check without rerunning or re-counting diagnostics.
Validation-reference fixture rollups schema-export `fixture_count` as a
non-negative integer, and executable validation requires it to equal the number
of nested fixture reports so compatibility preflight cannot silently drop or
double-count fixture observations. Executable validation also requires the
top-level rollup `status` to match the nested report statuses, preventing stale
`pass` summaries from hiding failed fixture reports.
Standalone validation-reference reports likewise require their `status` to match
nested check statuses, so a stale passing fixture report cannot hide a failed
field-level check.
An executable global registry guard now requires every registered artifact
contract to have a curated validation-reference fixture model ID and every
curated `artifact.*` fixture model ID to name a registered contract. The current
boundary covers 120 of 121 contracts. The sole explicit exclusion is the
self-describing `validation_reference_fixture_report.v1` rollup, whose fixture
would otherwise recursively require itself; a focused assertion keeps that
bootstrap exception singular and registered.
Schema validation reports and batch reports also schema-export their scalar
count fields (`error_count`, `warning_count`, `remediation_count`,
`file_count`, `artifact_count`, and `skipped_count`) as non-negative integers,
matching executable row-derived validation. Standalone and batch schema
validation reports pin their executable artifact-contract validation models in
runtime validation and schema export, so stale model identifiers cannot pass
schema-only handoffs.
Timeline preservation exports now constrain
`timeline_preservation_report.v1` and `timeline_preservation_status.v1` model
fields to their executable artifact-only model constants, and the preservation
report `source` field plus generated report/status `model_limits` lists export
to match runtime validation.
Focused schema-reference coverage exact-regenerates the checked-in
`study_results/timeline_preservation_report_v1.json` fixture through
`OrbitalDynamics.timeline_preservation_report/2` from deterministic mutable,
locked, completed, and invalid activity inputs before schema validation,
pinning protection count maps, preservation-sensitive routing, row evidence,
and the artifact-only no-schedule-mutation boundary.
Campaign-repair V2 preserves that incoming report at the distinct
`source_timeline_preservation_report` path. Full executable validation rejects
stale row-derived preserve/review counts, protection routing, stable identity,
or non-object values. Existing operator-review and Cadence adapters retain
exact pre-repair decisions and source summary context for review; the path
performs no repair scoring, candidate selection, timeline mutation, Cadence
write, or grant of operator authority.
Campaign-repair V2 separately preserves an incoming aggregate timeline-diff
summary at `source_timeline_diff_summary`. Full executable validation pins
source/replacement and diff counts, changed fields, stable timeline identity,
status and approval transitions, protection decisions, duplicate/invalid input
evidence, and complete review rows. Existing review and Cadence adapters route
those exact summary rows without applying a source transition, mutating or
publishing the repaired timeline, writing to Cadence, commanding, or granting
operator authority.
Campaign-repair V2 preserves CandidateRefresh's ordered top-level
`source_window_lineage` collection without reconstruction or deduplication.
Executable validation pins every embedded lineage row at its exact array index
and rejects any explicitly declared contract drift while retaining legacy
CandidateRefresh rows without a contract tag. The existing candidate-diff
review and Cadence adapters use the collection only to attach exact
invalidated/replacement candidate lineage and source-window payloads; it cannot
change candidate matching, repair scoring or selection, mutate a schedule,
write to Cadence, command activity, or grant operator authority.
Campaign-repair V2 also preserves incoming dependency-impact evidence at
`source_timeline_dependency_impact_summary`. Full executable validation pins
changed source and dependent activity/timeline counts, stable identity lists,
source/replacement scope, dependency and exclusivity edges, status, and
operator-action routing. Existing review and Cadence adapters retain exact
actionable impact rows without applying a transition, mutating or publishing
the repaired timeline, writing to Cadence, or granting operator authority.
CandidateRefresh realized-state evidence is separately retained at
`source_realized_state_snapshot`, distinct from the repair request's operative
`realized_state_snapshot`. Full executable validation pins realized activities,
spacecraft states, provider/trust-boundary metadata, row-derived counts, and
model limits. Existing review and Cadence adapters retain exact snapshot
context on realized-feedback rows without replacing current repair state,
changing repair decisions, mutating a schedule, writing to Cadence, or granting
operator authority.
Incoming lifecycle-state evidence is retained separately at
`source_timeline_lifecycle_state_summary`. Full executable validation pins
planned/realized and review counts, identity collections, transition and action
maps, complete rows, review rows, duplicate timeline identity, protection
context, and approval changes. Existing review and Cadence adapters preserve
exact actionable rows without applying lifecycle or approval transitions,
mutating or publishing the repaired timeline, writing to Cadence, commanding,
or granting approval/operator authority.
CandidateRefresh activity-precondition evidence is retained as the ordered,
plural `source_timeline_activity_precondition_summaries` collection. Direct
source summaries precede canonical summaries, and every map is retained without
deduplication or first-map selection. Full executable validation reports drift
at each exact array index; existing review and Cadence adapters preserve that
indexed provenance and complete source context without changing repair scores,
mutating a schedule, writing to Cadence, commanding activity, or granting
operator authority.
CandidateRefresh per-activity lifecycle evidence is likewise retained as the
ordered, plural `source_timeline_activity_lifecycle_states` collection. Direct
source states precede canonical states, and every map is retained without
deduplication or first-map selection. Full executable validation pins each
state at its exact array index; existing review and Cadence adapters preserve
the complete planned/realized status, approval, protection, transition, and
operator-action context without applying a transition, changing repair
decisions, mutating a schedule, writing to Cadence, commanding activity, or
granting authority.
CandidateRefresh's heterogeneous activity-state family is retained separately
at `source_timeline_activity_states`. The collection preserves activity
feedback, status-transition, and approval-transition contracts in stable family
order, with source before canonical maps for each family and no deduplication or
first-map selection. Full executable validation dispatches each array index to
its declared contract; existing review and Cadence adapters retain exact state
and indexed provenance without affecting current-state derivation, changing
repair decisions, applying a transition, mutating a schedule, writing to
Cadence, commanding activity, or granting authority.
CandidateRefresh standalone preservation-status evidence is retained as the
ordered, plural `source_timeline_preservation_statuses` collection, independently
from `source_timeline_preservation_report`. Direct source statuses precede
canonical statuses, and every map is retained without deduplication or first-map
selection. Full executable validation pins lifecycle, lock, approval,
protection, identity, and review fields at each exact array index; existing
review and Cadence adapters preserve the exact source status without changing
derived preservation decisions, mutating a schedule, writing to Cadence,
commanding activity, or granting authority.
CandidateRefresh publication evidence is retained as the ordered, plural
`source_timeline_publication_summaries` collection. Direct source summaries
precede canonical summaries, and every map is retained without deduplication or
first-map selection. Full executable validation pins publication sequence and
lineage, source and superseded artifacts, downstream invalidations, dependency
and diff context, and the declared publication-authority claim at each exact
array index. Existing review and Cadence adapters always require operator review
and do not publish, republish, execute invalidations, accept source authority,
mutate a schedule, write to Cadence, command activity, or grant authority.
CandidateRefresh transition-application evidence is likewise retained at
`source_timeline_transition_application_report`, distinct from V2's repair-time
`timeline_transition_application_report`. Full executable validation pins
application counts, selected source, transition decisions, protected-change
withholding, integrity evidence, and operator-action routing. Existing review
and Cadence adapters preserve those exact source decisions without applying the
source timeline, mutating the repair result, writing to Cadence, or granting
operator authority.
The aggregate transition evidence is separately retained at
`source_timeline_transition_application_summary`. Full executable validation
pins exact application, selection, review, transition, integrity, and
operator-action counts and identity collections. Existing review and Cadence
adapters preserve the summary's complete review applications and aggregate
source context without applying a transition, mutating the repair result,
writing to Cadence, or granting operator authority.
Incoming operational-timeline evidence is retained separately at
`source_operational_timeline_report` rather than being overwritten by V2's
repair-time `operational_timeline_report`. Full executable validation pins row
counts, stable timeline identity, activity context, integrity/precondition
evidence, provider results, Cadence readiness, and operator actions. Existing
review and Cadence adapters preserve actionable rows under the
`planned_not_commanded` boundary without applying the source schedule or
performing a Cadence write.
Incoming command-window evidence is retained at
`source_command_window_report`, distinct from V2's repair-time
`command_window_report`. Full executable validation pins window and
review-required counts, stable timeline identity, command/contact direction,
station and timing context, policy/integrity evidence, provider results, and
Cadence readiness. Existing review and Cadence adapters preserve exact
actionable source rows without mutating the schedule, executing a command,
writing to Cadence, or granting command authority.
Incoming maneuver-review evidence is retained at
`source_maneuver_review_report`. Full executable validation pins maneuver and
review-required counts, stable scenario/maneuver identity, timing, frame,
delta-v, model and execution-uncertainty context, and any approval/escalation
evidence. Existing review and Cadence adapters preserve exact actionable rows
under the report's `review_only_no_command_execution` boundary without
changing repair scoring or selection, approving a maneuver, commanding,
executing, or writing to Cadence.
`study_results/timeline_preservation_status_v1.json` now feeds a curated
`timeline_preservation_status.v1` validation-reference fixture. The observations
check locked/protected activity preservation status, timeline identity,
protection decision/category/reason, preservation/review booleans, model limits,
and no-schedule-mutation assumptions.
Timeline activity status-state, approval-state, and lifecycle-state exports
likewise pin generated `model_limits` to the executable timeline model-limit
list, so stale activity preflight handoffs cannot widen their artifact-only
boundary.
The checked-in `study_results/timeline_lifecycle_state_summary_v1.json`
fixture is refreshed from
`OrbitalDynamics.timeline_lifecycle_state_summary/3` and exact-compared before
schema validation. The fixture preserves command-window context, duplicate
timeline-identity review routing, record/preserve/review count maps,
top-level and row-level model limits, invalid-input flags, and the
artifact-only no-operator-authority/no-schedule-mutation boundary.
Candidate-rejection report exports likewise constrain
`candidate_rejection_report.v1` to the artifact-only candidate-rejection model
constant, a string `source`, and the exact generated `model_limits` list,
matching executable validation for generated rejection explanation reports.
Timeline-feedback report exports constrain `timeline_feedback_report.v1` to the
planned-versus-realized activity reconciliation model constant, matching
executable validation for generated feedback reconciliation reports.
Operational-timeline report exports constrain `operational_timeline_report.v1`
to the selected-activity operational-context model constant and exact timeline
model-limit list, matching executable validation for generated timeline handoff
reports.
Timeline-diff report exports constrain `timeline_diff_report.v1` to the
timeline-identity activity-diff model constant and exact timeline model-limit
list, matching executable validation for generated standalone diff reports.
Schema migration reports export and executable-validate registry contract
counts, status-count maps, migration-action maps, model identity, deprecation
warning counts, and row summaries for caller-declared deprecated or future
contracts. The report is artifact-only: it does not rewrite artifacts, grant
migration authority, or certify backward compatibility. Validation-reference
fixtures now cover both deprecated-contract and future-contract hints, so stale row-derived
status/action rollups fail before migration guidance is trusted.
Operator-review and Cadence-import handoff contracts executable-validate lifted
station-calendar trust-boundary and reservation-match count maps as
non-negative integer maps, matching the exported JSON Schema shape.
Operational-readiness, quality-gate, operator-review, and Cadence-import
handoff schemas also expose operator-training requirement counts, requirement
count maps, and required operator role/training/certification/qualification
arrays with the same shapes executable validation accepts.
Operator-review and Cadence-import handoff schemas expose nested source
operational-readiness/quality-gate report identity, readiness/status, gate
count, and quality-gate count-map shapes, matching the copied source-report
drift checks used by executable validation.
Operator-review and Cadence-import artifacts built from `quality_gate_report.v1`
also expose top-level quality-gate gate counts, status/classification count
maps, gate-ID routing maps, quality-gate row-ID routing maps, and gate ID sets
so import-readiness queues can route gate summaries without reopening rows.
Standalone station-reservation summaries now export
`station_reservation_report.v1` and executable-validate affected-contact,
provider-contention, review-count, reservation status-count, reservation-match,
and reservation-ID summaries against their emitted rows.
Resource-projection battery aggregate handoff fields
(`total_battery_energy_consumed_wh`, `total_battery_energy_generated_wh`,
`net_battery_energy_delta_wh`, and `peak_battery_overuse_wh`) are explicitly
schema-exported and executable-validated on operator-review rows, Cadence import
rows, nested source review rows, and source resource-projection evidence so
adapter consumers can type-check the compact battery roll-forward evidence.
Model-acceptance reports also expose optional deterministic model-ID routing
maps by row status, validation level, and intended use. Executable validation
checks those maps and optional `status_counts` against the emitted rows when
present, so import gates can route accepted, review-required, blocked, and
unknown model evidence without recounting rows.
Executable validation rejects stale model-acceptance status, validation-level
counts, status-count maps, model-ID routing maps, validation-record lists,
input-model assumptions, and model-limit drift.
It also rejects stale model-acceptance model strings, and schema export pins the
registry model-acceptance classifier used by generated reports.
Candidate-refresh model-acceptance replay summaries derive validation-level
counts and model-ID routing maps from rows when rows are present, so stale
top-level validation-level and routing aggregates cannot steer branch-local
review/blocking pressure. Compact no-row model-acceptance handoffs also derive
model row counts, accepted/review/blocked counts, unknown-model counts, and
validation-level counts from present model-ID routing maps before falling back
to duplicated top-level scalar counters.

Validation reference fixture reports now include an
`operational_readiness_report.v1` artifact-contract fixture generated from a
ready Cadence import manifest. The fixture checks readiness classification,
gate counts, import-evidence counts, and model-limit evidence without treating
the report as external operations validation.
Executable validation rejects stale readiness classification/status, gate
counts, gate-declared import/resource evidence counts and maps, model-limit
drift, and missing artifact-only assumptions.
The underlying `cadence_import_manifest.v1` fixture also checks reported and
row-derived import status, Cadence import status, import action/side,
source-review queue/type, and manifest row-ID routing maps so stale manifest
summaries fail before readiness classification consumes them.
Executable validation rejects stale manifest row/readiness counts, import
action/status maps, model-limit drift, and artifact-only execution/authorization
boundary drift.

The validation-reference fixture set also includes
`study_results/leo_constellation_campaign.json` as a `result_artifact.v1`
wrapper fixture. Its observations check stable top-level product counts,
embedded campaign activity/contact counts, execution status, run identity, and
payload metrics section and artifact-body counts without treating the artifact
as an external mission validation. Executable validation rejects stale payload
metrics top-level key counts, missing or extra payload metric sections, and
negative section byte or row-count values.
Additional `result_artifact.v1` wrapper fixtures now cover
`study_results/leo_access_demo.json`,
`study_results/leo_access_demo_manifest.json`,
`study_results/ground_track_crossings.json`,
`study_results/raise_apogee_search.json`,
`study_results/candidate_refresh_v1.json`,
`study_results/candidate_refresh_orbit_data_v1.json`,
`study_results/leo_dispersion_monte_carlo.json`, and
`study_results/mission_plan_checkout.json`. These observations check event-rich
access/eclipse counts, ground-track crossing counts, maneuver recommendation
counts, candidate-refresh wrapper counts, mission-plan checkout maneuver-review
presence, Monte Carlo and constraint report presence, execution scenario
counts, run metadata, and payload metrics without treating the artifacts as
external mission validation.

Validation safety-case summaries are artifact-only rollups, not new authority
grants. Use `OrbitalDynamics.validation_safety_case_summary/2` when a handoff
needs one compact view of model-acceptance, operational-readiness,
quality-gate, schema-validation, schema-validation batch, and fixture evidence.
A blocked or review-required summary means the evidence bundle needs review or
remediation; it does not certify models, write to Cadence, or approve import.
The summary emits `validation_safety_case_summary.v1`, and executable
validation checks row-derived evidence counts, status counts, and routing maps
against the evidence rows. Its exported schema pins the artifact-only model
`artifact_only_validation_safety_case_summary`, matching runtime validation so
stale safety-case summary model identifiers cannot pass schema-only handoff
checks.
Validation fixture report evidence is classified from nested fixture report
statuses when they are present, so a stale top-level fixture-rollup `pass`
cannot make failed fixture evidence appear accepted in a safety-case handoff.
Model-acceptance evidence is also classified from model rows when they are
present, deriving status counts and model-ID routing maps from the rows before
trusting stale top-level accepted/review/blocked aggregates.
Quality-gate evidence derives review and blocked counts from gate rows when
they are present, so stale top-level passed gate counts cannot make blocked
gate evidence appear accepted in a safety-case handoff.
Operational-readiness evidence derives review and blocked status/counts from
readiness gate rows when they are present, so stale top-level import-eligible
status cannot hide blocked readiness gates in the safety-case handoff.
Single schema-validation evidence derives status and counts from `errors` and
`warnings` issue lists when they are present, so stale top-level pass/zero-count
fields cannot hide schema issues in a safety-case handoff.
Candidate-refresh validation-safety-case replay summaries use those evidence
rows to derive source-report evidence counts, pressure counts, input-contract
maps, and evidence-reference maps when rows are present, so stale top-level
safety-case aggregates cannot steer review/blocking/schema/fixture pressure.
Compact no-row safety-case handoffs also derive evidence row counts and
accepted/review/blocked evidence counts from present evidence-status and
evidence-reference maps before falling back to duplicated top-level scalar
counters.
The summary includes deterministic evidence references grouped by summary status
and input contract, so handoff consumers can route blocked and review-required
evidence without re-scanning the evidence rows.
The validation-reference fixture set includes the checked-in
`study_results/validation_safety_case_summary_v1.json` summary as a curated
artifact-contract case. Its observations verify stable evidence counts, status
counts, evidence-reference routing maps, model-limit count, and the
no-certification/no-operator-authority boundary. The checked-in safety-case
example now includes blocked schema-validation evidence preserved through both
operator-review and Cadence-import containers, and
`study_results/validation_reference_fixtures.json` verifies those blocked
handoff evidence counts and duplicate schema-validation evidence references.
Focused schema-reference coverage also regenerates the checked-in fixture
exactly through `OrbitalDynamics.validation_safety_case_summary/2` from
deterministic model-acceptance and schema-validation evidence before schema
validation, pinning case identity, evidence status/reference routing, model and
schema-validation row evidence, model limits, and the
no-certification/no-authority boundary.
Batch schema-validation evidence contributes aggregate schema issue counts and
nested report pass/fail counts without rerunning lint.
Wrapper artifacts may provide `schema_validation_batch_report` or
`source_schema_validation_batch_report`; safety-case summaries discover both.
Operator-review packages and Cadence-import manifests may also preserve
`source_schema_validation_report` rows; safety-case summaries lift those rows
as schema-validation evidence without treating the review/import container as a
certification authority.

Validation reference fixture reports also include a
`station_calendar_report.v1` artifact-contract fixture for a stale but
plausible provider reservation hold. The fixture checks reservation-overlap
counts, row-derived reservation match-status maps, stale hold evidence,
affected-contact counts, affected duration, reservation match-status contact
routing, and the artifact-only no-provider-reservation execution boundary
without calling a station-calendar provider or mutating a schedule. Executable
validation rejects stale reservation match-status maps that no longer match
affected contacts.
The same stale hold also feeds a `station_reservation_report.v1` fixture so
compatibility checks cover the compact reservation-summary contract, including
row-derived reservation review counts, status maps, match-status maps,
reservation IDs, reservation-ID routing by match status, and the
no-provider-write boundary. Executable validation also rejects stale
reservation status maps and reservation ID lists.
The checked-in `study_results/station_calendar_report_v1.json` overlay report
is also observed as a curated fixture, covering the two-contact/two-entry
station-calendar handoff shape and its row-derived reservation overlap evidence
without provider reservation side effects. Executable validation rejects stale
affected durations, station-calendar trust maps, and station-calendar
availability, status, direction, and ground-station maps, plus model
identifiers and model-limit drift in that checked-in overlay report.
Focused schema-reference coverage also exact-regenerates the checked-in full
report through `OrbitalDynamics.station_calendar_report/3` from deterministic
contact candidates and declared provider entries before schema validation,
pinning affected-contact routing, reservation-match routing, trust-boundary
routing, station availability/status/direction maps, provider-contention
evidence, and exact `model_limits`. Schema export pins the same
station-calendar overlay model for schema-only handoff checks.
The full report fixture remains an artifact-only no-provider-reservation/no-
schedule-mutation/no-Cadence-write handoff.

Validation reference fixture reports also include a
`provider_counteroffer_report.v1` artifact-contract fixture generated from
declared station-calendar counteroffer evidence. The fixture checks
counteroffer counts, row-derived scalar counteroffer/reviewability/cost/deadline
observations, lock deadline, timing-shift evidence, and the artifact-only
no-provider-write boundary without accepting offers or mutating schedules.
Executable schema validation also rejects stale top-level cost totals, status
maps, and operator-action maps that no longer match the counteroffer rows.
Candidate-refresh replay summaries use row-derived counteroffer status and
required-action maps when row evidence is present, so stale top-level
counteroffer aggregates cannot steer branch-local review pressure.

`study_results/operational_readiness_report_v1.json` is the checked-in
interoperability fixture for readiness handoff consumers. It validates as
`operational_readiness_report.v1` and carries a ready-import example with
gate/evidence counts, row-derived gate status/classification maps, gate ID
routing maps, and artifact-only model limits; the validation-reference rollup
points directly at this artifact.
Executable validation rejects stale gate-derived readiness classification,
readiness level, report status, gate counts, gate-declared evidence counts/maps,
model-limit drift, artifact-only assumption drift, and stale
operational-readiness report model strings. Schema export pins the
artifact-only operational-readiness classifier model and capability
`model_limits` used by generated reports.
The compact readiness gate summary schema export likewise pins the
artifact-only operational-readiness gate-summary model and `model_limits` used
by generated summaries.
`study_results/operational_readiness_gate_summary_v1.json` now checks in that
compact gate summary generated from the readiness fixture. Its
validation-reference coverage exact-compares the public facade output before
schema validation and observes source identity, readiness/import/status
classification, row-derived gate counts, gate status/classification routing
maps, non-passed gates, model limits, and no-Cadence-write/no-approval/no-import
assumptions without writing Cadence, importing activities, executing commands,
granting operator authority, or mutating schedules.
The compact import-eligibility summary schema export pins the
artifact-only import-eligibility model and `model_limits` used by generated
summaries, keeping adapter-facing import decisions tied to the executable
artifact-only boundary.
`study_results/operational_import_eligibility_summary_v1.json` now checks in
that compact import-eligibility view generated from the readiness fixture. Its
validation-reference coverage exact-compares the public facade output before
schema validation and observes source identity, readiness/import/status
classification, import eligibility, gate counts, non-passed gates, model
limits, and no-Cadence-write/no-approval/no-import assumptions without writing
Cadence, importing activities, executing commands, granting operator authority,
or mutating schedules.
Operator-review packages and Cadence-import manifests derived directly from the
readiness report now also expose the compact readiness report ID,
readiness/import/status classification, and gate counts at top level for
adapter routing.
The public execution-boundary summary reuses that readiness evidence to keep
import eligibility separate from command execution, Cadence writes, and
operator authority; analysis-only markers such as simulation, trade study, and
not-for-execution remain handoff evidence only. Its schema export pins the
artifact-only execution-boundary summary model and `model_limits` used by
generated summaries.
`study_results/operational_execution_boundary_summary_v1.json` now checks in
the compact execution-boundary view generated from the readiness fixture. Its
validation-reference coverage exact-compares the public facade output before
schema validation and observes source identity, readiness/import/status
classification, import eligibility, handoff-only and execution/Cadence/operator
authority flags, execution boundary, operational-mode gate context, gate counts,
non-passed gates, model limits, and no-Cadence-write/no-command-execution/
no-import assumptions without writing Cadence, importing activities, executing
commands, granting operator authority, or mutating schedules.

The validation-reference fixture set also includes a curated
`quality_gate_report.v1` artifact generated from the readiness fixture. Its
observations check source readiness identity, row-derived gate/row counts,
status and classification count maps, executable stale row-derived gate map
checks, gate ID routing maps, model-limit count, and the no-authority execution
boundary. Runtime validation and schema export pin its artifact-only model
`artifact_only_operational_quality_gate_report` and `model_limits`, so handoff
queues reject stale quality-gate report model identifiers or model-limit lists
before deriving summaries or review rows.
The public quality-gate summary schema export pins the artifact-only
quality-gate summary model and `model_limits` used by generated row-derived
triage summaries.
`study_results/operational_quality_gate_summary_v1.json` now feeds a curated
validation-reference fixture for the base summary family. The fixture observes
row-derived review and non-passed gate counts, status/classification routing,
non-passed gate and row IDs, and the no-Cadence-write/no-authority assumptions.
Focused checked-in fixture coverage exact-compares the public
`OrbitalDynamics.operational_quality_gate_summary/1` facade output from
`study_results/quality_gate_resource_pressure_v1.json` before schema
validation.
Executable validation rejects stale row-derived quality-gate classification,
readiness level, status, gate counts/maps, gate ID routing groups, nested
readiness/quality source-gate handoff drift, copied source-report summary
drift, model-limit drift, and no-Cadence-write/no-authority boundary drift.
CandidateRefresh replay also derives reconstructed readiness/status,
classification, gate counts, and per-status count maps from
`quality_gate_row_ids_by_status` for compact no-row
`operational_quality_gate_summary.v1` handoffs, preventing stale top-level
summary counts from steering branch-local quality-gate pressure.

Resource-pressure examples are checked in alongside the ready-import fixture:
`study_results/operational_readiness_resource_pressure_v1.json`,
`study_results/quality_gate_resource_pressure_v1.json`,
`study_results/operator_review_resource_pressure_v1.json`, and
`study_results/cadence_import_resource_pressure_v1.json`. They exercise the
review-only resource-availability path and show the lifted pressure count,
reason count map, sorted reason IDs, unavailable-resource reason IDs, and
blocking-dimension count map on readiness, quality-gate, operator-review, and
Cadence-import handoff rows.
The public quality-gate unavailable-resource summary derives review/import
routing directly from those quality-gate rows, grouping blocked contact IDs by
blocking dimension, spacecraft, and gate status while keeping Cadence writes,
operator approval, and command execution out of scope.
Its exported schema pins the artifact-only model
`artifact_only_quality_gate_unavailable_resource_summary` and the summary's
artifact-only `model_limits`, matching runtime validation so adapter queues
cannot accept stale model identifiers or trust-boundary declarations for this
summary family.
The validation-reference registry and checked-in
`study_results/operational_quality_gate_unavailable_resource_summary_v1.json`
fixture now include a generated
`operational_quality_gate_unavailable_resource_summary.v1` case for that
summary family. The fixture observes unavailable-resource reason maps,
blocking-dimension counts, blocked-contact routing, quality-gate row/status
routing maps, and no-Cadence-write/no-authority assumptions, and executable
verification rejects stale reason maps, blocked-contact maps,
quality-gate-row routing maps, and row-status counts before adapter queues can
trust the compact summary.
Focused schema-reference coverage also regenerates the checked-in fixture
exactly through
`OrbitalDynamics.operational_quality_gate_unavailable_resource_summary/2` from
the checked-in `quality_gate_resource_pressure_v1.json` source report before
schema validation, pinning source identity, unavailable-resource pressure
counts, resource-availability row IDs, status routing, model limits, and the
no-Cadence-write/no-command-execution boundary; validation-reference checks now
reject stale checked-in quality-gate row routing before downstream
resource-pressure replays consume it.
CandidateRefresh replay also derives reconstructed generic quality-gate row
counts from `quality_gate_row_ids_by_status` when present, while preserving the
resource-specific pressure counts and blocked-contact routing maps from the
compact unavailable-resource summary. V3 strategy scoring routes those
unavailable-resource quality-gate risks into
`resource_availability_pressure_penalty` instead of the broader
`quality_gate_pressure_penalty`, so antenna/payload/station availability
pressure remains planner-visible as resource pressure.
Operational-readiness resource-availability gates now preserve the same
resource pressure counts and reason maps in branch risk indicators, and V3
strategy scoring routes them into `resource_availability_pressure_penalty`
instead of the broader `operational_readiness_pressure_penalty`.
The public quality-gate schema-validation summary publishes
`operational_quality_gate_schema_validation_summary.v1` for Cadence-import
quality-gate rows carrying schema-validation evidence, preserving pass/fail and
issue counts plus blocked and failed quality-gate row IDs without granting
import authority. Its schema export pins the artifact-only quality-gate
schema-validation summary model and `model_limits` used by generated summaries.
`study_results/operational_quality_gate_schema_validation_summary_v1.json`
feeds a curated validation-reference fixture for that summary family. The
fixture observes top-level and map-derived schema-validation counts, status
maps, blocked/failed row routing, gate routing, and the no-Cadence-write/
no-authority assumptions, and executable verification rejects stale fail counts
plus stale blocked-row evidence before adapter queues can trust the compact
summary.
Focused checked-in fixture coverage exact-compares the public
`OrbitalDynamics.operational_quality_gate_schema_validation_summary/1` facade
output from the deterministic planned-activity ready-import source with failed
schema-validation evidence before schema validation.
CandidateRefresh replay also derives reconstructed quality-gate row counts from
`quality_gate_row_ids_by_status` when present, preventing stale compact
schema-validation row counts from inflating branch-local quality-gate pressure.
V3 strategy scoring routes schema-validation summary risks into the existing
`validation_refresh_pressure_penalty` rather than the broader
`quality_gate_pressure_penalty`, so failed schema evidence stays visible in the
validation score-term family.
Operational-readiness schema-validation gates also preserve fail, error,
warning, remediation, status, and failed-row evidence in branch risk indicators,
and route that pressure into `validation_refresh_pressure_penalty` instead of
the broader `operational_readiness_pressure_penalty`.
The public quality-gate operator-training summary publishes
`operational_quality_gate_operator_training_summary.v1`, preserving role,
training, certification, and qualification routing from operator-training
quality-gate rows without granting import authority. Its schema export pins the
artifact-only quality-gate operator-training summary model and `model_limits`
used by generated summaries.
`study_results/operational_quality_gate_operator_training_summary_v1.json`
feeds a curated validation-reference fixture for that summary family. The
fixture observes top-level and map-derived requirement counts, role/training/
certification/qualification routing, review-required/review-only row routing,
and the no-Cadence-write/no-authority assumptions, and executable verification
rejects stale requirement counts, stale role/training requirement routing keys,
and stale review-row evidence before adapter queues can trust the compact
summary.
Focused checked-in fixture coverage exact-compares the public
`OrbitalDynamics.operational_quality_gate_operator_training_summary/1` facade
output from the deterministic planned-activity ready-import source with
operator-training requirements before schema validation.
CandidateRefresh replay also derives reconstructed generic quality-gate row
counts from `quality_gate_row_ids_by_status` when present, while preserving
operator-training requirement counts and role/training/certification/
qualification routing from the compact summary. V3 strategy scoring now emits a
dedicated `operator_training_pressure_penalty` for those branch-local
operator-training quality-gate risks instead of folding them into the broader
`quality_gate_pressure_penalty`.
Operational-readiness operator-training gates now use the same dedicated
`operator_training_pressure_penalty` when branch risk indicators carry
role/training/certification/qualification requirements, instead of folding that
pressure into the broader `operational_readiness_pressure_penalty`.
The public quality-gate import-readiness summary publishes
`operational_quality_gate_import_readiness_summary.v1`, preserving freshness,
import-status, and Cadence-import status routing from those same rows, including
stale/unknown freshness row IDs, import-preparation row IDs, and blocked import
row IDs. Its schema export pins the artifact-only quality-gate
import-readiness summary model and `model_limits` used by generated summaries.
`study_results/operational_quality_gate_import_readiness_summary_v1.json` feeds
a curated validation-reference fixture for that summary family. The fixture
observes top-level and map-derived readiness counts, freshness/import/Cadence
status maps, review/stale/import-preparation/blocked row routing, analysis-only
boundaries, and the no-Cadence-write/no-authority assumptions, and executable
verification rejects stale ready-for-import counts plus stale row-derived
freshness evidence before adapter queues can trust the compact summary.
Focused checked-in fixture coverage exact-compares the public
`OrbitalDynamics.operational_quality_gate_import_readiness_summary/1` facade
output from the deterministic planned-activity ready-import source with stale
freshness evidence before schema validation.
CandidateRefresh replay also derives reconstructed quality-gate status,
generic ready/review/analysis/blocked row routing, and row counts from
`quality_gate_row_ids_by_status` when present, preventing stale compact
import-readiness top-level arrays from steering branch-local quality-gate
pressure. V3 strategy scoring now emits a dedicated
`import_readiness_pressure_penalty` for branch-local import-readiness
quality-gate risks instead of folding freshness, import-preparation, and
blocked-import evidence into the broader `quality_gate_pressure_penalty`.
Operational-readiness import gates now preserve freshness/import/Cadence status
evidence in branch risk indicators and use the same dedicated
`import_readiness_pressure_penalty` instead of folding that pressure into the
broader `operational_readiness_pressure_penalty`.
The same readiness gate also consumes contact-allocation station pressure
handoffs: ground-station reserved, unavailable, zero-capacity, and
reduced-capacity allocation reasons become row-derived availability reason
counts before import eligibility is classified.
Adapter-boundary evidence now distinguishes declared, missing, and untrusted
trust-boundary statuses. Missing trust-boundary evidence keeps adapter-shaped
rows review-only, while explicitly unknown or untrusted trust-boundary evidence
blocks import eligibility and is exported on readiness, quality-gate,
operator-review, and Cadence-import handoff rows.

`study_results/candidate_refresh_resource_provenance_v1.json` is the
corresponding `candidate_refresh.v1` fixture for branch-local provenance. Its
`provenance.source_reports` summaries preserve the same readiness and
quality-gate resource pressure counts, reason maps, sorted reason IDs, and
unavailable-resource IDs, plus derived station availability reason IDs and
count maps; this fixture has no station-specific resource reason, so the
station collections are empty while keeping the source paths under
`mission_state.source_operational_readiness_report` and
`mission_state.source_quality_gate_report`. The artifact is also registered in
the validation-reference fixture set, where the observations check the refresh
product counts, nonzero source-report family/row totals, and derived
quality-gate/readiness gate counts, status maps, import-classification maps,
readiness-level maps, and trust-boundary status. Candidate-refresh schema
validation applies the same resource-context shape checks to those source-report
summaries that readiness and quality-gate rows use: pressure counts,
resource/station reason-count maps, and analysis-mode count maps must be
non-negative integers; reason ID and trust-boundary lists must contain strings;
and trust-boundary status must be a string when present. When both pressure
counts and reason-count maps are present, executable validation requires the
scalar pressure count to equal the reason-count map sum. The checked-in
`candidate_refresh.v1` JSON Schema and schema bundle export the same nested
`provenance.source_reports` resource, analysis-mode, and trust-boundary context
properties for downstream compatibility tooling.
Executable validation also checks the generic source-report summary shape:
`paths` must be a string list, and `count`/`row_count` must be non-negative
integers. The public candidate-refresh source-report replay summary uses the
same boundary for derived path and trust-boundary status aggregates: malformed
non-string path/status values can remain visible in raw preserved provenance for
inspection, but they do not become aggregate keys or routed replay paths.
Contact-intent summary validation rejects stale summary model and
source-artifact identity strings, and `contact_intent_summary.v1` schema exports
publish those same constants for replay tooling that consumes compact
contact-intent summaries. It also emits row-derived direction counts and
direction-routing maps and rejects stale direction counts or route maps that no
longer match the compact direction/contact/capacity aggregates.
`study_results/contact_intent_summary_v1.json` now feeds a curated
`contact_intent_summary.v1` validation-reference fixture. The observations
check contact and capacity-pack counts, direction/station/direction-and-station
routing maps, required-capacity source routing, capacity fractions, model
limits, and artifact-only no-provider-reservation/no-schedule-mutation
assumptions.
V2 repair artifacts separately preserve an accepted CandidateRefresh summary at
`source_contact_intent_summary`. Full nested validation pins exact aggregate
counts, contact identities, direction/station and capacity-pack routing,
required capacity fractions, provenance, and boundary assumptions before
existing operator-review and Cadence adapters derive direction-scoped review
rows. This handoff does not allocate or reserve provider capacity, mutate a
schedule, write to Cadence, or grant operator authority.

`study_results/candidate_refresh_v1.json` now feeds a curated
`candidate_refresh.v1` validation-reference fixture. The observations check the
checked-in refresh artifact's candidate, contact-intent, refreshed-window,
warning, source-report provenance counts, and embedded validation-record
vocabulary.
The validation-reference registry also includes a generated CandidateRefresh
contact-intent direction replay fixture. It checks row-derived contact-intent
direction counts, contact IDs by direction, capacity-pack fraction/contact
routing maps, and trust-boundary status without contact generation, contact
allocation, candidate selection, import approval, or Cadence writes.
The registry also includes a generated CandidateRefresh contact-filter replay
fixture. It checks contact-filter source-report provenance counts, row-derived
candidate suppression, invalid contact-input evidence, direction and
station-suppression routing maps, branch-local contact-filter pressure
booleans, and trust-boundary status without contact allocation, candidate
selection, import approval, or Cadence writes.
The registry also includes a generated CandidateRefresh candidate-rejection
replay fixture. It checks candidate-rejection source-report provenance counts,
row-derived rejection reasons, required operator actions, candidate/station
routing maps, branch-local rejection pressure booleans, and trust-boundary
status without candidate selection, import approval, or Cadence writes.
The registry also includes a generated CandidateRefresh freshness replay
fixture. It checks freshness source-report provenance counts, source paths,
stale/unknown status maps, reason lists/count maps, branch-local freshness
pressure booleans, and trust-boundary status without refresh mutation, import
approval, or Cadence writes.
The registry also includes a generated CandidateRefresh refresh-budget replay
fixture. It checks refresh-budget source-report provenance counts, path keys,
input/kept/dropped candidate counts, kept/dropped candidate ID keys,
invalid-limit reason maps, branch-local budget pressure booleans, and
trust-boundary status without refresh mutation, import approval, or Cadence
writes.
The registry also includes a generated CandidateRefresh station-calendar replay
fixture. It checks station-calendar source-report provenance counts,
affected-contact status, direction, and ground-station maps, provider-contention
group/source/provider-entry routing, trust-boundary status, and branch-local
station/provider pressure booleans without schedule mutation, candidate
selection, import approval, or Cadence writes.
The registry also includes a generated CandidateRefresh objective-gap replay
fixture. It checks objective-satisfaction, objective-tradeoff, and score-term
source-report provenance counts, row-derived gap/status/term maps, source
activity routing, aggregate objective-gap branch-local pressure booleans,
score-term branch-local pressure booleans, and trust-boundary status without
objective generation, score recalculation, candidate selection, import
approval, or Cadence writes.
The registry also includes a generated CandidateRefresh constraint replay
fixture. It checks constraint source-report provenance counts, row-derived
downlink/resource-margin/status/metric/resource/spacecraft maps, branch-local
constraint pressure booleans, and trust-boundary status without objective
generation, resource mutation, candidate selection, import approval, or Cadence
writes.
The registry also includes a generated CandidateRefresh link-capacity replay
fixture. It checks link-capacity source-report provenance counts, row-derived
throughput totals, station/spacecraft/direction/contact routing maps,
downlink-requirement shortfall routing, branch-local link-capacity pressure
booleans, and trust-boundary status without contact allocation, candidate
selection, import approval, or Cadence writes.
The registry also includes a generated CandidateRefresh resource-filter replay
fixture. It checks resource-filter source-report provenance counts, row-derived
candidate suppression, invalid resource-summary input evidence,
resource/blocking-dimension/direction routing maps, branch-local
resource-filter pressure booleans, and trust-boundary status without resource
filtering, candidate selection, import approval, or Cadence writes.
The registry also includes a generated CandidateRefresh resource-projection
replay fixture. It checks projected-resource and invalid-input counts, resource
pressure status/type/direction maps, activity routing, and trust-boundary
status without resource mutation, candidate selection, import approval, or
Cadence writes.
The registry also includes a generated CandidateRefresh quality-gate replay
fixture. It checks gate counts, readiness/import/status/classification maps,
trust-boundary status, branch-local review/import/resource pressure booleans,
and resource-availability count/reason evidence from quality-gate resource
pressure without granting operator authority, candidate selection, import
approval, or Cadence writes.
The registry also includes a generated CandidateRefresh operational-readiness
replay fixture. It checks readiness/import/status maps, gate counts, and
trust-boundary status from imported operational-readiness evidence without
granting execution authority, operator authority, candidate selection, import
approval, or Cadence writes.
That fixture now uses the resource-pressure readiness source and pins
branch-local review, import, and resource pressure booleans plus resource
availability count/reason evidence, so stale replay-pressure routing fails
fixture verification before branch-local refresh consumers trust the compact
provenance.
The registry also includes a generated CandidateRefresh timeline-activity
precondition replay fixture. It checks blocked/review precondition status,
dependency and exclusivity routing, invalid-activity input evidence, overlap
allowance, and trust-boundary status without mutating schedules, granting
operator authority, selecting candidates, approving imports, or writing to
Cadence.
The registry also includes a generated CandidateRefresh timeline-lifecycle
state replay fixture. It checks planned/realized lifecycle counts,
record/preserve/review routing, duplicate timeline-identity review evidence,
operator-action maps, and trust-boundary status without mutating schedules,
granting operator authority, selecting candidates, approving imports, or
writing to Cadence.
The registry also includes a generated CandidateRefresh timeline-activity
lifecycle replay fixture. It checks single-activity lifecycle transition
decisions, status/approval/protection category maps, required operator-action
maps, import-action maps, action routing, and trust-boundary status without
mutating schedules, granting operator authority, selecting candidates,
approving imports, or writing to Cadence.
The registry also includes a generated CandidateRefresh timeline-transition
application replay fixture. It checks selected-integrity review and issue
counts, missing-dependency issue-type routing, application status maps,
operator-action maps, and trust-boundary status without schedule mutation,
candidate selection, import approval, or Cadence writes.
`study_results/branch_comparison_report_v1.json` and
`study_results/candidate_diff_report_v1.json` now feed curated
validation-reference fixtures. The observations check branch ranking and
selected-branch counts, approval-status routing maps, resource-risk maps,
no-execution branch-score assumptions, candidate diff counts, semantic change
reason maps, replacement routing maps, and model-limit boundaries.
Executable validation rejects stale branch-comparison branch counts, selected
branch routing, per-row score deltas, and row list-count fields when they drift
from emitted branch rows. It also rejects stale branch-comparison model/source
identity strings and exports the same constants used by generated V3 strategy
branch-comparison reports. Candidate-diff validation rejects stale collection
counts, changed-field aliases, and semantic-change reason lists that drift from
emitted diff rows, rejects stale candidate-diff model strings, and exports the
same model constant used by generated candidate-diff reports.
The checked-in V3 strategy artifact is regenerated through the public campaign
strategy facade, so its embedded branch-comparison rows now pin the current
dedicated pressure score-term keys instead of a schema-valid older subset.
`study_results/candidate_diff_row_v1.json` now feeds a curated
`candidate_diff_row.v1` validation-reference fixture. The observations check
row identity, diff reason, changed-field order/counts, semantic-change
reason/detail counts, matched prior candidate identity, target metadata, and
target-priority objective routing. Executable validation rejects stale
changed-field counts, changed-field aliases, and semantic-change reason lists
on standalone candidate-diff rows.
`study_results/candidate_rejection_report_v1.json` now feeds a curated
`candidate_rejection_report.v1` validation-reference fixture. The observations
check rejected, not-rejected, reviewable, and invalid-input counts,
rejection-reason routing, required operator-review action counts, and the
artifact-only no-selection/no-schedule-mutation model-limit boundary.
Executable validation rejects stale rejected counts, rejection-reason maps,
candidate ID sets by rejection reason, required operator-action counts, and
reviewable candidate ID lists, plus stale generated `model_limits`.
Candidate-refresh replay summaries also derive rejection-reason and
required-action maps from rows when present, preventing stale top-level
candidate-rejection aggregate maps from steering branch-local
review pressure.
`study_results/refresh_budget_report_v1.json` and
`study_results/monte_carlo_reproducibility_report_v1.json` now feed curated
validation-reference fixtures. The observations check deterministic keep/drop
budget counts, kept/dropped candidate IDs, no-search budget assumptions, seeded
scenario generation counts, RNG/seed metadata, dispersion sigma vectors,
covariance/model-limit boundaries, and known-limit counts.
Executable validation rejects stale refresh-budget input/kept/dropped counts,
duplicate kept/dropped candidate IDs, and kept/dropped ID-list overlap that
would make budget routing ambiguous.
It also rejects stale refresh-budget model strings, and schema export pins the
deterministic candidate-limit-after-filters model used by generated reports.
Executable validation also rejects stale Monte Carlo generated-scenario counts,
duplicate generated-scenario IDs, and known-limit/model-limit lists that drift
from the capability contract.
It also rejects stale Monte Carlo reproducibility model strings, and schema
export pins the seeded independent-normal Cartesian dispersion model used by
generated reports.
`study_results/execution_report_v1.json` now feeds a curated
`execution_report.v1` validation-reference fixture. The observations check
distributed execution counts, failed-scenario isolation, task-supervisor and
chunking metadata, backend-acceptance evidence, and model-limit boundaries.
Executable validation rejects stale execution scenario/completion/failure
counts, failed-scenario list mismatches, status drift, execution-plan scenario
count drift, and node-distribution totals that no longer match scenario count.
`study_results/freshness_report_v1.json` now feeds a curated
`freshness_report.v1` validation-reference fixture. The observations check
accepted-state freshness status, state-quality routing, horizon offset
thresholds, stale/unknown reason counts, and the artifact-only
no-schedule-mutation boundary.
Executable validation rejects stale freshness status, stale/unknown reason-list
drift, state-quality routing drift, horizon/snapshot policy mismatches, and
model-limit lists that no longer match the candidate-refresh capability
contract.
It also rejects stale freshness-report model strings, and schema export pins
the accepted-snapshot horizon/quality freshness model used by generated reports.
`study_results/manifest_field_reference.json` and
`study_results/study_manifest_lint_v1.json` now feed curated
validation-reference fixtures. The observations check manifest field catalog
counts, supported vocabulary counts, compatibility and identity policy
versions, generated-ID policy bounds, lint preflight status/counts, output
bounds, and semantic-validator identity.
Executable validation rejects stale manifest field counts, duplicate field
paths, top-level required field-list drift, invalid activation-section routing,
and supported-vocabulary drift from manifest schema enum evidence.
Executable validation rejects stale study-manifest-lint status and
error/warning counts, duplicate requested outputs, and requested outputs that
are no longer present in the supported-output vocabulary.
`study_results/approval_requirement_v1.json`,
`study_results/policy_decision_v1.json`, and
`study_results/policy_bundle_v1.json` now feed curated validation-reference
fixtures. The observations check approval requirement authority routing,
policy-decision escalation metadata, representative policy-bundle rule and
authority maps, artifact-only no-authority-lookup boundaries, and
no-command/no-schedule model limits.
Executable validation rejects stale approval-requirement decision
classification, policy-bundle identity, root rule-match evidence, and
required-authority escalation evidence.
Executable validation rejects stale policy-decision classification,
approval-requirement and risk counts derived from rule matches, escalation
rule IDs that no longer reference rule-match evidence, and policy model-limit
drift.
Executable validation rejects policy-bundle duplicate action-rule IDs,
provenance bundle IDs that no longer match the bundle identity, stale
artifact-only boundary assumptions, missing action-rule classification/reason
routing, escalation metadata without required-authority routing, and policy
model-limit drift.
`study_results/policy_bundle_ground_network_allocation_v1.json` is also
observed as a ground-network policy fixture. It checks contact-schedule
authority routing, unavailable/reduced-capacity station rules, contention and
contact-allocation review triggers, missing trust-boundary review, command
direction review, duplicate/insufficient-capacity block rules, and artifact-only
no-authority assumptions.
`study_results/policy_bundle_operator_review_queue_authority_v1.json` is
observed as an operator-review queue authority fixture. It checks one
artifact-only rule for each review authority boundary, deterministic
escalation-queue counts, queue-authority rule IDs, and the no-command,
no-schedule-mutation, no-workflow-execution limits.
`study_results/policy_bundle_command_contact_authority_v1.json` is observed as
a command/contact authority fixture. It checks command, contact-schedule,
tracking, mission-planning, and Cadence-import boundary authority routing,
escalation queue counts, station-calendar command-window rules, operator-action
rule coverage, and artifact-only execution limits.
`study_results/policy_bundle_maneuver_authority_v1.json`,
`study_results/policy_bundle_resource_projection_authority_v1.json`, and
`study_results/policy_bundle_timeline_protection_v1.json` are observed as
domain authority fixtures. They check maneuver, resource-model, and timeline
protection authority routing, blocked/review classification maps, escalation
queue counts, deterministic rule IDs, and artifact-only execution limits.
The remaining checked-in policy bundles are also observed:
`policy_bundle_conservative_ops_v1.json`,
`policy_bundle_contact_command_review_v1.json`,
`policy_bundle_degraded_payload_guard_v1.json`,
`policy_bundle_default_v1.json`, and
`policy_bundle_organization_adapter_v1.json`. These fixtures check conservative
fallback blocking, contact/command review-only routing, degraded-payload block
and exemption rules, empty-rule default fallback limits, organization-adapter
provenance, no-workflow execution, and artifact-only execution boundaries.
`study_results/backend_acceptance_policy_v1.json`,
`study_results/validation_tolerance_policy_v1.json`,
`study_results/validation_record_v1.json`, and
`study_results/validation_check_v1.json` now feed curated
validation-reference fixtures. The observations check backend acceptance tier
routing, tolerance policy vocabulary and boundaries, validation record
model identity, evidence/tolerance rows, known-limit counts, and scalar
validation-check expected/observed/tolerance/error values. Executable validation rejects stale
backend reference implementation tier routing plus
validation-tolerance policy level vocabulary drift and
validation-record level/tolerance-map drift plus
validation-check pass/fail status and numeric error values when expected,
observed, and tolerance fields provide enough evidence to derive them.
`study_results/capability_catalog_v1.json`,
`study_results/optimizer_contract_v1.json`,
`study_results/strategy_branch_v1.json`, and
`study_results/strategy_recommendation_v1.json` now feed curated
validation-reference fixtures. The observations check public capability catalog
counts, model identity, exact executable contract registry routing, deterministic greedy
optimizer selection and ordering metadata, optimizer candidate/selected/ranked
count consistency,
standalone V3 branch event/risk/score routing and score/policy summary
consistency, and strategy recommendation ranking, tradeoff, and
operator-review routing consistency. Capability catalog observations also pin
CandidateRefresh accepted source-report input order, accepted-input counts, and
source-report helper counts so replay-family metadata changes are caught by the
fixture compatibility surface. The pinned catalog now observes the expanded
CandidateRefresh input surface, including relay data path, operational-readiness
sub-summary, provider-counteroffer review, station-reservation review, and
operational quality-gate summary families.
Executable validation rejects stale capability-catalog model strings, and
schema export pins the public catalog model used by generated discovery
artifacts.
Runtime public environment capability records from
`OrbitalDynamics.Environment.model_capabilities/0` and
`OrbitalDynamics.Environment.provider_capabilities/0` also feed curated
validation-reference fixtures. The observations check
`environment_model_capability.v1` and `environment_provider_capability.v1`
identity, category/model/source metadata, validation-level vocabulary,
interpolation and coverage policy, network-access boundaries,
output/body/parameter counts, and known-limit counts.
`study_results/campaign_request_lint_v1.json`,
`study_results/study_benchmark.json`,
`study_results/distributed_chunk_sweep.json`,
`study_results/distributed_concurrency_sweep.json`,
`study_results/distributed_diagnostic_sweep.json`,
`study_results/distributed_monte_carlo_chunked.json`,
`study_results/distributed_monte_carlo_scaling.json`,
`study_results/monte_carlo_scaling.json`,
`study_results/nx_study_benchmark.json`, and
`study_results/validation_reference_report_v1.json` now feed curated
validation-reference fixtures. The observations check request-lint status,
source-plan routing, persisted benchmark result/baseline counts, distributed
mode rows, chunk/concurrency/Monte Carlo option sweep shape, backend coverage,
manifest identity, standalone validation-reference report check routing, and
schema-level benchmark row counts derived from result signatures and per-node
trajectory counts.
`study_results/accepted_planning_state_simple.json`,
`study_results/accepted_planning_state_opm.json`,
`study_results/accepted_planning_state_oem.json`,
`study_results/proposed_contact_v1.json`, and
`study_results/invalidated_candidate_v1.json` now feed curated
validation-reference fixtures. The observations check accepted-state provenance,
quality, vector dimensions, adapter input format, maneuver-feedback counts, and
executable rejection of stale `provenance.state_estimate_count` values that drift
from emitted `spacecraft_states`, proposed-contact timing/source-window/Cadence
import metadata plus top-level/nested source-window identity drift, and
invalidated-candidate replacement, source-target context, and semantic-change
routing.
`study_results/planned_activity_v1.json`,
`study_results/realized_activity_v1.json`, and
`study_results/plan_delta_v1.json` now feed curated validation-reference
fixtures. The observations check planned activity timeline identity,
dependency/exclusivity counts, resource trust metadata, execution uncertainty,
and executable rejection of stale planned timeline identity drift, realized
activity status and planned-vs-actual data volume, Cadence feedback adapter
provenance plus metadata identity drift, plan-delta repair status, approval
requirement, and top-level/source timeline identity drift.
`study_results/candidate_activity_v1.json`,
`study_results/contact_intent_v1.json`,
`study_results/refreshed_window_v1.json`, and
`study_results/source_window_lineage_v1.json` now feed curated
validation-reference fixtures. The observations check generated candidate
activity IDs, score/objective counts, score-term sums, sampled-window identity
and provenance, contact-intent approval routing, policy classification, Cadence
import metadata identity, no-provider/no-schedule boundaries, refreshed-window
event-timing assumptions plus sample-cadence coverage, and source-window
lineage identity/type consistency.
`study_results/spacecraft_state_estimate_v1.json`,
`study_results/realized_state_snapshot_v1.json`, and
`study_results/remaining_horizon_v1.json` now feed curated validation-reference
fixtures. The observations check state-estimate source/provenance and quality
metadata, quality sigma triplets, vector dimensions, realized snapshot
status/type maps, row-derived degraded/status counts, contact-failure counts,
provider feedback metadata, no-schedule-mutation boundaries, and remaining-
horizon duration/output-step timing bounds.
`study_results/maneuver_execution_delta_v1.json` and
`study_results/maneuver_recommendation_v1.json` now feed curated
validation-reference fixtures. The observations check maneuver execution status
and epoch/source/provenance/quality metadata, delta-v vector dimensions and
magnitude consistency, recommendation model limits, required operator-review
metadata, and the recommendation-only no-command-execution boundary.
`study_results/timeline_diff_report_v1.json`,
`study_results/timeline_transition_application_report_v1.json`, and
`study_results/timeline_transition_application_selected_integrity_v1.json` now
feed curated validation-reference fixtures. The observations check timeline
source/replacement counts, diff status and changed-field maps, operator-action
row routing, review-required counts, row-derived timeline-diff
status/transition/action/changed-field maps, row-derived diff/action row
routing, row-derived transition application status/decision/action maps,
status/approval transition maps, application ID routing,
selected/preserved/withheld counts, selected-integrity issue/action/dependency
routing, review-gate assumptions, and no-schedule-mutation boundaries. Focused
schema-reference coverage also
refreshes and exact-regenerates the checked-in
`study_results/timeline_diff_report_v1.json` fixture through
`OrbitalDynamics.timeline_diff_report/3` from deterministic added, removed,
protected changed, and execution-uncertainty changed activity inputs before
schema validation, pinning valid/invalid input counts, transition decision
counts, status/approval transition category maps, and execution-uncertainty row
evidence. It also refreshes and exact-regenerates
`study_results/timeline_transition_application_report_v1.json` through
`OrbitalDynamics.timeline_transition_application_report/3` from deterministic
protected-change, added, unchanged, and removed activity inputs before schema
validation, pinning selected-activity precondition status/count fields as part
of the public report surface. The selected-integrity fixture exact-regenerates
the missing-dependency review-gate case through the same public facade, pinning
row-derived selected issue-type, required-action, application-ID, and missing
dependency routing. Executable validation rejects stale timeline-diff
row/status/review counts, changed-field and action maps, transition-application
counts, row-derived decision/action maps, selected-integrity routing, and
timeline model-limit drift, rejects stale transition-application report model
strings, and exports the same model and model-limit constants with string source
boundaries.
Candidate-refresh transition-application replay summaries
also derive application status, transition decision, required action, duplicate
scope maps, application counts, and duplicate identity counts from application
rows when present, so stale top-level transition aggregates cannot steer replay
pressure. Selected-activity, review-required, preserved-source,
recorded-replacement, and withheld-review counts are row-derived under the same
stale-aggregate boundary. Candidate-refresh operational-feedback provenance
also derives source timeline-diff status and required-action maps from rows when
rows are present, preventing stale top-level timeline-diff aggregates from
steering branch-local feedback pressure.
`study_results/timeline_activity_precondition_summary_v1.json` now feeds a
curated `timeline_activity_precondition_summary.v1` validation-reference
fixture. The observations check blocked/review precondition counts, blocked and
review type lists, row-derived precondition status/type maps, timeline identity,
and artifact-only/no-authority assumptions. Executable validation rejects stale
top-level precondition counts and stale row-derived type maps, so precondition
summaries remain review evidence instead of silently becoming schedule,
operator, or resource authority. Generated summaries now carry the exact
Timeline `model_limits` list, and schema export/runtime validation reject stale
timeline execution-boundary assumptions.
Focused validation and schema-reference coverage also regenerate the checked-in
fixture exactly through
`OrbitalDynamics.timeline_activity_precondition_summary/1` from deterministic
activity input before schema validation, pinning payload, resource-block, and
degraded-mode precondition rows plus the no schedule mutation/no-authority
boundary.
`study_results/timeline_activity_state_v1.json` now feeds a curated
`timeline_activity_state.v1` validation-reference fixture. The observations
check review-required state rows, planned/realized activity identity,
status/match/protection count maps, review activity IDs, row-derived transition
categories, and artifact-only/no-schedule-mutation/no-command-execution
assumptions. Executable validation rejects stale row counts and stale
row-derived match-strategy maps before compact activity-state handoffs can
steer review/import adapters.
Focused validation-reference and schema-reference coverage exact-regenerates the
checked-in activity state fixture through
`OrbitalDynamics.timeline_activity_state/3` from deterministic planned and
realized command inputs before schema validation, pinning lifecycle-derived
status categories, lock/executed booleans, protection evidence, trust-boundary
status, reconciliation rows, exact model limits, and the
no-schedule-mutation/no-authority/no-command boundary.
Checked-in single-activity status, approval, and lifecycle-state fixtures are
also exact-regenerated by validation-reference and schema-reference coverage
through
`OrbitalDynamics.timeline_activity_status_state/2`,
`OrbitalDynamics.timeline_activity_approval_state/2`, and
`OrbitalDynamics.timeline_activity_lifecycle_state/2` before schema validation.
These fixture checks pin normalized transition decisions, review/import routing,
planned and realized activity contexts, explicit `invalid_activity_input`
evidence, and the artifact-only `no-schedule-mutation`, `no-authority`,
`no-command`, and `no-Cadence-write` boundary for single-activity handoffs.
The checked-in lifecycle-state summary fixture is likewise regenerated through
`OrbitalDynamics.timeline_lifecycle_state_summary/3`, pinning duplicate-identity
review routing, record/preserve/review counts, and the summary-level
no-import/no-command/no-authority boundary. Schema and validation-reference
challenge coverage rejects stale lifecycle-summary operator-action reason count
and review-routing aggregates before compact lifecycle summaries can steer
review/import routing.
`study_results/timeline_dependency_impact_summary_v1.json` now feeds a curated
`timeline_dependency_impact_summary.v1` validation-reference fixture. The
observations check source/replacement counts, changed-source counts, dependent
activity counts, impacted ID routing, row-derived scope/status/action/reason
maps, row IDs by required action, and no-schedule-mutation/no-authority
assumptions. Executable validation rejects stale dependent-activity counts and
stale row-derived operator-action reason maps before dependency-impact summaries
can steer review/import routing.
Focused schema-reference coverage also regenerates the checked-in fixture
exactly through `OrbitalDynamics.timeline_dependency_impact_summary/3` from
deterministic source/replacement activities before schema validation, pinning
changed-source counts, dependent activity and timeline routing,
dependency/exclusivity impact maps, explicit exclusivity timeline-ID routing,
model limits, and the
no-schedule-mutation/no-authority boundary.
`study_results/timeline_diff_summary_v1.json` now feeds a curated
`timeline_diff_summary.v1` validation-reference fixture. The observations check
compact diff counts, changed-field counts, transition-decision and
required-action maps, review timeline routing by operator action, row-derived
status/approval transition categories, and no-schedule-mutation/no-authority
assumptions. Executable validation rejects stale review-required counts and
stale row-derived transition category maps before compact diff summaries can
steer review/import routing.
Focused schema-reference coverage also regenerates the checked-in fixture
exactly through `OrbitalDynamics.timeline_diff_summary/3` from deterministic
source/replacement activities before schema validation, pinning diff counts,
changed-field routing, status/approval transition routing, model limits, and
the no-schedule-mutation/no-authority boundary.
`study_results/timeline_integrity_report_v1.json` now feeds a curated
`timeline_integrity_report.v1` validation-reference fixture. The observations
check dependency/exclusivity review rows, issue-type counts, required-action and
operator-reason maps, review activity/timeline routing, flattened
dependency/exclusivity evidence IDs, and no-schedule-mutation assumptions.
Focused validation and schema-reference coverage also exact-regenerate the
checked-in fixture through `OrbitalDynamics.timeline_integrity_report/2` from
deterministic dependency-order, missing-dependency, and exclusivity-overlap
activities before schema validation, pinning row issue evidence and review
routing to the public facade.
Executable validation rejects stale issue counts and stale row-derived
issue-type maps before integrity summaries can steer review/import routing.
Campaign-repair V2 preserves the incoming report at the distinct
`source_timeline_integrity_report` path. Full executable validation rejects
stale row-derived issue counts, dependency/exclusivity identity routing, or
non-object values. Existing operator-review and Cadence adapters retain exact
pre-repair rows and source summary context for review; the path performs no
repair scoring, candidate selection, timeline mutation, Cadence write, or
grant of operator authority.
`study_results/timeline_transition_application_summary_v1.json` now feeds a
curated `timeline_transition_application_summary.v1` validation-reference
fixture. `study_results/timeline_transition_application_selected_integrity_summary_v1.json`
also feeds a curated summary fixture for the selected missing-dependency review
gate. The observations check selected/review/preserved/withheld counts,
selected-integrity issue/action/dependency routing, application status and
transition-decision maps, required-action routing, review timeline IDs by
operator action, row-derived review-application transition categories, and
no-schedule-mutation/no-authority assumptions.
CandidateRefresh replay of generated transition summaries is also pinned by a
validation-reference fixture, including selected-integrity review/issue counts
and required timeline-integrity review actions.
Executable validation rejects stale review-required counts, stale
selected-integrity counts, stale selected-integrity routing, and stale
row-derived required-action maps before compact transition summaries can steer
review/import routing.
Focused schema-reference coverage also regenerates the checked-in fixture
exactly through
`OrbitalDynamics.timeline_transition_application_summary/3` from deterministic
source/replacement activities before schema validation, pinning selected,
review, preserved, and withheld routing, transition status maps, model limits,
and the no-schedule-mutation/no-authority boundary. The selected-integrity
summary fixture exact-regenerates the same missing-dependency review-gate case
through the public facade before schema validation.
`study_results/timeline_publication_summary_v1.json` now feeds a curated
`timeline_publication_summary.v1` validation-reference fixture. The observations
check publication identity/status, supersession, downstream invalidation IDs,
explicit downstream invalidation status, dependency-impact review routing,
nested timeline-diff counts, changed-field maps, review timeline IDs, and
no-schedule-mutation/no-authority assumptions.
Focused schema-reference coverage also regenerates the checked-in fixture
exactly through `OrbitalDynamics.timeline_publication_summary/2` from
deterministic source/replacement timeline evidence, dependency-impact summary,
and timeline-diff summary before schema validation, pinning publication status,
downstream invalidation routing, nested impact/diff evidence, model limits, and
the no-notification/no-schedule-mutation/no-authority boundary to the public
facade output.
`study_results/operational_timeline_report_v1.json` is also observed with
row-derived operational-kind, activity-status, approval-status,
Cadence-import-status, required-action, timeline-integrity issue, and row-ID
routing maps so stale timeline handoff summaries fail compatibility checks.
Focused schema-reference coverage refreshes and exact-regenerates that checked-in
fixture through `OrbitalDynamics.operational_timeline_report/2` from
deterministic mission-plan activities before schema validation, pinning
precondition status/counts, invalid-activity counters, command-window context,
timeline-integrity routing, operational-kind/import/action maps, and the
planned-not-commanded/no-schedule-mutation/no-command-execution boundary to the
public facade output.
Candidate-refresh operational-timeline replay summaries use those row-derived
maps and row-derived integrity counts, so stale top-level operational-timeline
aggregate maps or issue-count fields cannot steer branch-local replay pressure.
Operational-feedback provenance for source operational-timeline reports uses
the same row-derived required-action maps when rows are present, so stale
top-level required-action aggregates cannot steer branch-local feedback
pressure.
`study_results/timeline_feedback_report_v1.json` now feeds a curated
validation-reference fixture and focused schema-reference coverage
exact-regenerates it through `OrbitalDynamics.reconcile_timeline_feedback/3`
from deterministic planned/realized activity inputs before schema validation. The
observations check planned/realized reconciliation counts, feedback kind and
match strategy maps, execution-uncertainty counts, nested operator-review and
Cadence import handoff counts, operational-feedback key counts and provenance,
row-derived status, kind, match, import, transition, and activity-routing maps,
and no-schedule-mutation boundaries. Executable validation rejects stale row
counts, row-derived maps, execution-uncertainty counts, and timeline-feedback
model-limit drift. The candidate-refresh timeline-feedback source summary also
derives replay status, feedback-kind, and match-strategy maps from rows so stale
top-level aggregate maps cannot steer branch-local replay pressure.
Operational-feedback provenance for source timeline-feedback reports also
derives status, feedback-kind, match-strategy, and Cadence-import status maps
from rows when rows are present, preventing stale top-level aggregates from
steering branch-local feedback pressure.
`study_results/station_calendar_provider_v1.json` now feeds a curated
`station_calendar_provider.v1` validation-reference fixture. The observations
check provider identity, entry order/counts, station routing,
maintenance/reserved availability counts, zero-capacity and reservation
metadata, provenance, trust boundary, and no-provider-reservation assumptions.
Executable validation rejects duplicate provider entry IDs before provider
calendars are consumed by calendar reports.
`study_results/provider_counteroffer_review_summary_v1.json`,
`study_results/provider_counteroffer_import_readiness_summary_v1.json`, and
`study_results/provider_counteroffer_plan_impact_summary_v1.json` now feed
curated provider-counteroffer summary fixtures. The observations check
review/import/impact counts, deadline-status routing, required-action maps,
timing/cost impact IDs, affected station/provider entry IDs, and
no-provider-write, no-Cadence-write, and no-offer-acceptance assumptions.
`study_results/cadence_import_manifest_v1.json` now feeds a curated
`cadence_import_manifest.v1` validation-reference fixture. The observations
check import readiness/blocking counts, Cadence import status maps, source
review queue maps, import-status row routing, no-Cadence-write boundaries,
authorization boundaries, and model-limit evidence.
Executable validation rejects stale Cadence-import row counts, readiness counts,
import action/status maps, no-write/no-authorization-boundary drift, and
model-limit drift. It also rejects stale Cadence-import manifest model strings,
and schema export pins the artifact-only manifest model and `model_limits` used
by generated handoffs.
`study_results/command_window_report_v1.json` and
`study_results/constraint_report_v1.json` now feed curated validation-reference
fixtures. The observations check command-window row-derived operator-action
routing, cadence-import and approval status maps, window-type maps, required
action row IDs, artifact-only execution boundary evidence, constraint status
and metric maps, threshold operator counts, row-derived status-routed
constraint IDs, and model-limit boundaries. Executable validation rejects stale
command-window scalar counts, window-type counts, review-required counts, and
source-window lineage counts that no longer match rows, rejects stale
command-window model strings, and exports the same model constant with a string
source boundary. Constraint report validation now also rejects stale
unique-constraint counts, row counts, overall status, and status-count maps that
no longer match constraint rows, and schema export pins exact model-limit lists
for known artifact-metric, campaign-planner, and campaign-repair constraint
report models while leaving future models extensible.
Candidate-refresh operational-feedback provenance for source command-window
reports derives required-action maps from rows when rows are present, so stale
top-level command-window required-action aggregates cannot steer branch-local
feedback pressure.

Checked-in schema-validation reports also feed validation-reference fixtures.
`study_results/schema_validation_report_v1.json` is observed for validation
mode, status, validated contract identity, issue/remediation counts, and
schema-validation model limits. Executable validation rejects stale standalone
schema-validation status and issue/remediation counts that no longer match the
reported rows. `study_results/schema_validation_batch_report_v1.json` is
observed for directory batch file/artifact/skipped counts, nested report
pass/fail counts, aggregate issue/remediation counts, explicit status-count
maps, and the same model-limit boundary. Executable validation rejects stale
batch status, scalar counts, status-count maps, model identifiers, and
model-limit drift so the batch rollup cannot hide nested schema-validation
failures or skipped-artifact drift. The schema-lint task regression suite also
regenerates the `study_results` batch report and compares it with the
checked-in artifact so new public fixtures cannot leave the batch rollup stale.
V2 repair artifacts separately preserve an accepted CandidateRefresh batch at
`source_schema_validation_batch_report`. Full nested validation pins every
artifact path/report, status, issue/remediation aggregate, skipped input, model
limit, and validation mode before existing operator-review and Cadence adapters
route warning/error rows. This review-only handoff does not change repair
validity or import eligibility, write to Cadence, grant import authority, or
execute work.
`study_results/resource_projection_report_v1.json` is observed for selected
activity/resource summary counts, flow-row counts, pressure-row counts,
storage/downlink pressure totals, warnings, source-quality/trust maps, and
model-limit boundaries. Executable validation rejects stale activity/resource
summary counts, row-derived warnings, source-quality/trust maps, and
resource-projection model identity or model-limit drift; schema export pins the
same known thin projection model set. Newly generated resource-projection
reports also carry row-derived pressure count, pressure-type, pressure
spacecraft ID, and activity/spacecraft ID maps by pressure type; executable
validation rejects those fields when they drift from projected resource and flow
rows. Resource projection also review-gates stale explicit storage or battery
state-of-charge margins in source `resource_summary.v1` inputs before they can
influence roll-forward math.
Focused checked-in fixture coverage exact-compares the public
`OrbitalDynamics.resource_projection_flow_summary/1` facade output from
`study_results/resource_projection_report_v1.json` before schema validation,
pinning the compact flow summary's activity/resource counts, pressure routing,
energy/storage/downlink totals, actual data-volume evidence counts and
under/over/exact variance routing, model limits, and artifact-only boundaries
for no resource-state reconciliation, no subsystem simulation, no Cadence
writes, no activity imports, no command execution, and no schedule mutation.
Campaign-repair V2 preserves that incoming aggregate separately at
`source_resource_projection_flow_summary`. Full executable validation pins its
spacecraft projections, activity resource flow, row-derived pressure and
latency routing, storage/downlink/battery totals, invalid inputs, source
quality, trust boundaries, and model limits. Existing review and Cadence
adapters route exact spacecraft and activity-flow evidence without changing
repair scoring, recomputing resource state, mutating the schedule, writing to
Cadence, commanding, or granting operator authority.
`study_results/resource_projection_battery_handoff_v1.json`,
`study_results/operator_review_resource_projection_battery_handoff_v1.json`,
and `study_results/cadence_import_resource_projection_battery_handoff_v1.json`
are observed as an end-to-end battery handoff challenge path. The fixture checks
flow-derived consumed/generated/net battery energy and peak overuse values on
the source resource projection, the operator-review handoff row, the Cadence
import handoff row, and the nested source-review evidence.
The general `operator_review_package.v1` fixture also checks row-derived review
counts, review-type maps, required-operator-action maps, queue maps, and review
row IDs by type so stale package summaries fail before Cadence import handoff
generation consumes them. Runtime validation and schema export pin its
artifact-only model `artifact_only_operator_review_package` and package-level
`model_limits`, so stale operator-review package model identifiers or
capability-limit lists fail before review rows are trusted as Cadence-facing
handoff evidence.
Executable validation rejects stale operator-review package review counts,
row-derived review-type, queue, and required-action maps, model-limit drift, and
artifact-only boundary drift.
Generated validation-reference fixtures also cover stale battery
state-of-charge and storage-margin source summaries for resource projection and
direct resource filtering, checking the invalid-summary IDs, reason counts, and
candidate/projection row preservation boundaries. Executable validation also
rejects stale invalid-summary counts and projection invalid-summary IDs that no
longer match the preserved invalid input rows.
`study_results/resource_summary_v1.json` is observed for planning-grade
resource identity, derived battery/storage/power margins, downlink capacity
metadata, availability and degraded flags, activity suppression and
incompatibility lists, source quality, trust boundary, and provenance
assumptions. Executable validation also rejects stale explicit storage or
battery state-of-charge margins that disagree with supplied capacity/used
evidence.
Focused schema-reference coverage also round-trips the checked-in fixture
exactly through `OrbitalDynamics.resource_summary_from_map!/1` and
`OrbitalDynamics.resource_summary_to_map/1` before schema validation, pinning
spacecraft identity, mode, resource-margin evidence, availability/degraded
flags, source quality, trust boundary, activity suppression/incompatibility
lists, assumptions, and provenance without adding propagation or schedule
mutation behavior.
`study_results/resource_filter_report_v1.json` is observed for kept/suppressed
candidate counts, invalid and duplicate candidate counts, source-quality/trust
maps, suppressed-reason and resource-blocking routing maps, and model-limit
boundaries. Direct resource-filter inputs with stale explicit storage or
battery state-of-charge margins are preserved as invalid-summary review rows
instead of suppressing candidates. Executable validation also rejects stale
kept/suppressed counts, suppressed trust maps, and resource-filter model-limit
drift, rejects stale resource-filter model strings, and exports the same model
constant plus exact `model_limits` used by generated resource-filter reports and
compact summaries. Focused schema-reference coverage also exact-regenerates the
checked-in full report through `OrbitalDynamics.resource_filter_report/3` from
deterministic candidates, a declared wildcard resource summary, and explicit
policy thresholds before schema validation, pinning source-quality routing,
trust-boundary routing, suppression routing, exact `model_limits`, and optional
capability-derived assumptions for policy fields, aliases, tokens, provider
result keys, identity fields, station-calendar ID-list fields, suppression
reasons, and review statuses. Stale present assumption metadata is rejected
while omitted capability fields remain compatible. The full report and derived
compact summary fixtures remain artifact-only no-resource-propagation/no-
schedule-mutation/no-Cadence-write handoffs.
`study_results/resource_filter_summary_v1.json` now feeds a curated
`resource_filter_summary.v1` validation-reference fixture. The observations
check input/kept/suppressed/invalid counts, suppression review status,
suppressed IDs by reason, scenario, resource blocking dimension, source quality,
and trust-boundary status, duplicate counters, review rows, model limits, and
artifact-only no-resource-propagation/no-schedule-mutation assumptions.
V2 repair artifacts separately preserve an accepted CandidateRefresh summary at
`source_resource_filter_summary`. Full nested validation pins its exact counts,
ID and routing maps, review rows, invalid-summary inputs, source quality, trust
status, and model limits before existing operator-review and Cadence adapters
route its suppression evidence. This review-only handoff does not filter,
score, or select candidates, mutate a schedule, write to Cadence, or grant
operator authority.
`study_results/objective_satisfaction_report_v1.json` and
`study_results/objective_tradeoff_report_v1.json` are observed for objective
status maps, selected/satisfied/required totals, planned-not-executed
assumptions, ranking/tradeoff counts, score-term key shape, score totals,
selected-ranking assumptions, and model-limit boundaries.
Executable validation rejects stale objective-satisfaction objective counts,
status counts, objective routing by status, and row candidate/selected counts
when explicit candidate or selected ID lists are present, rejects stale
objective-satisfaction model strings, and schema export pins the campaign
selected-activity objective summary model used by generated reports. It also
rejects stale objective-tradeoff ranking counts, score-term key lists, and row
activity counts that no longer match emitted tradeoff rows, rejects stale
objective-tradeoff model strings, and schema export pins the campaign, repair,
and strategy score-term tradeoff model set used by generated reports.
`study_results/score_term_report_v1.json` and
`study_results/ranking_comparison_report_v1.json` are observed for score-term
row counts, selected-row counts, declared and row-derived score-term key counts,
score totals, pairwise ranking status maps, winner-change evidence, no-solver
assumptions, and model-limit boundaries. Executable validation rejects stale
score-term row counts, score-term key lists that no longer match emitted rows,
stale row-derived score-term key counts, and stale score-term model strings, and
exports the allowed model set with the string source boundary emitted by
generated score-term reports. The standalone score-term fixture is also pinned
to the checked-in V1 campaign artifact's embedded
`campaign_plan.score_term_report`, so fixture-chain drift is caught before
validation-reference checks run. It also
rejects stale ranking-comparison row/status counts, row-derived scenario
routing by status, and per-row rank/value deltas that no longer match the
compared ranks and values.
The V3 strategy golden fixture also pins the embedded strategy score-term report
from the public strategy facade. That nested report now covers 1107 score-term
rows, 41 score-term keys, 675 pressure rows, and dedicated pressure keys for
resource availability, execution feedback, approval boundaries, timeline
lifecycle/preconditions, link capacity, station calendars, quality gates,
provider counteroffers, and related planning evidence families.
Ranking-comparison validation also rejects stale model strings, and schema
export pins the scenario-ranking pairwise-delta model used by generated reports.
`study_results/maneuver_review_report_v1.json` and
`study_results/pareto_frontier_report_v1.json` are observed for maneuver review
counts, execution-uncertainty status maps, operator-action routing, no-command
review boundaries, Pareto frontier/dominated counts, objective key-count maps,
frontier routing maps, no-search assumptions, and model-limit boundaries.
Executable validation rejects stale maneuver-review counts, total delta-v,
operator-action maps, and model limits that drift from emitted review rows or
declared artifact-only review limits. It also rejects stale maneuver-review
model strings, and schema export pins the artifact-only review model used by
generated reports. Candidate-refresh operational-feedback
provenance for source maneuver-review reports also derives required-action maps
from rows when rows are present, so stale top-level maneuver-review
required-action aggregates cannot steer branch-local feedback pressure. It also rejects stale Pareto
alternative/frontier/dominated/objective counts, frontier/dominated ID sets, and
row objective-key lists that drift from objective values.
Pareto-frontier validation also rejects stale model strings, and schema export
pins the objective-vector Pareto-frontier model used by generated reports.
`study_results/operational_timeline_report_v1.json` is observed for operational
activity/contact/command counts, timeline-integrity issue and review counts,
dependency/exclusivity counts, status maps, operator-action row routing,
planned-not-commanded assumptions, and model-limit boundaries that schema export
also pins to the runtime timeline limit list.
Executable validation rejects stale operational-timeline row counts,
row-derived status/operator-action/import maps, and timeline-integrity issue
totals that no longer match the rows.
`study_results/contact_allocation_report_v1.json` is observed for contact
allocation counts, review-row counts, reported and row-derived
allocation/effective status and allocation-reason maps, row-derived scalar
allocation/contact counters, station-reservation and station-calendar trust
routing maps, row-derived reservation ID/owner/status evidence, executable
stale top-level reservation-list checks, station-reservation expiration
evidence, station-pressure status, precedence, and direction/station maps,
capacity-pack zero/default fields, nested contact-filter assumption metadata,
and model-limit boundaries. Focused schema-reference coverage also
exact-regenerates the fixture
through
`OrbitalDynamics.contact_allocation_report/3` from deterministic contact,
declared ground-network, and resource-summary inputs, preserving the
artifact-only no-provider-reservation/no-schedule-mutation/no-Cadence-write
boundary.
Executable validation rejects stale allocation status/reason maps, stale
reservation match-status maps, and stale reservation ID lists that no longer
match the allocation rows. Schema export pins the deterministic allocation
model constant, string source boundary, and exact `model_limits` used by
generated contact-allocation reports.
Contact-allocation summary schema export pins the artifact-only model constant
and exact `model_limits` used by generated compact allocation summaries.
Reservation-conflict summary schema export pins the artifact-only model
constant and exact `model_limits` used by generated compact
reservation-conflict handoff summaries.
`study_results/contact_allocation_capacity_pack_report_v1.json` is also
observed as a `contact_allocation_report.v1` reduced-capacity pack fixture. It
checks capacity-pack group counts, capacity fraction totals, selected/packed
and deferred contact routing, allocation reason maps, station-pressure status
maps, schema-visible reported capacity-pack status count maps, reported
capacity-pack contact IDs by status, required-capacity source maps,
packed/deferred ID sets, and declared station-calendar trust boundaries,
including nested contact-filter assumption
metadata. Focused schema-reference coverage exact-regenerates the full report
fixture through
`OrbitalDynamics.contact_allocation_report/3` from deterministic
reduced-capacity contacts and a declared station-calendar row. Executable
validation rejects stale pack status maps, contact pack-status maps,
contact-ID routing maps, capacity-demand maps, and packed/deferred ID sets that
no longer match the pack groups and allocation rows, and schema export pins the
artifact-only capacity-pack summary model constant plus `model_limits` used by
generated compact summaries. The fixture remains an artifact-only
no-provider-reservation/no-schedule-mutation/no-Cadence-write handoff.
Station-pressure summary schema export likewise pins the artifact-only model
constant and exact `model_limits` used by generated compact pressure summaries.
Candidate-refresh contact-allocation replay summaries also derive capacity-pack
status and contact-status maps from allocation rows when rows are present, so
stale top-level capacity-pack routing maps cannot steer branch-local pressure.
Candidate-refresh provider-reservation replay likewise preserves the compact
summary's full allocation rows and derives no-request counts, contact IDs, and
direction maps from those rows when present, so stale explicit no-request
aggregates cannot steer branch-local provider-reservation routing.
`study_results/contact_allocation_summary_v1.json` now feeds a curated
`contact_allocation_summary.v1` validation-reference fixture. The observations
check allocation counts/status maps, allocation-reason contact routing,
station-pressure routing by availability/status, reservation expiration and
match/status maps, review rows, model limits, and
no-provider-reservation/no-schedule-mutation
assumptions.
`study_results/contact_allocation_station_pressure_summary_v1.json` now feeds a
curated `contact_allocation_station_pressure_summary.v1` validation-reference
fixture. The observations check station-pressure and review counts, contact-ID
routing by ground station, availability, station-calendar status, precedence
availability/rank, direction and ground station, review rows, model limits, and
no-provider-reservation/no-schedule-mutation assumptions.
`study_results/contact_allocation_capacity_pack_summary_v1.json` now feeds a
curated `contact_allocation_capacity_pack_summary.v1` validation-reference
fixture. The observations check capacity-pack and reduced-pack counts,
status/contact-ID routing, selected and deferred required-capacity fractions,
required-capacity source maps, reduced capacity pack group routing, review rows,
model limits, and no-provider-reservation/no-schedule-mutation assumptions.
`study_results/contact_allocation_reservation_conflict_summary_v1.json` now
feeds a curated `contact_allocation_reservation_conflict_summary.v1`
validation-reference fixture. The observations check reservation contact,
conflict, and review counts, match/status/owner/expiration routing,
direction-and-station conflict maps, row subsets, model limits, and
no-provider-reservation/no-schedule-mutation assumptions.
Standalone `contact_allocation_capacity_pack_summary.v1` and
`contact_allocation_reservation_conflict_summary.v1` artifacts now also publish
direct operator-review packages and Cadence import manifests, preserving the
compact summary context in source review rows instead of requiring the full
allocation report or a candidate-refresh wrapper.
Campaign-repair V2 preserves a CandidateRefresh `contact_allocation_summary.v1`
at `source_contact_allocation_summary` as a distinct compact compatibility
boundary. Executable validation rejects stale row-derived allocation, trust,
reservation, resource, station, or capacity evidence and non-object source
values. The exact review rows and compact summary context flow through
operator-review and Cadence adapters without provider reservation, schedule
mutation, Cadence writes, or operator authority.
Campaign-repair V2 additionally preserves every CandidateRefresh
`contact_allocation_station_pressure_summary.v1` in direct-source-then-canonical
order at `source_contact_allocation_station_pressure_summaries`, without
deduplication or first-map selection. The existing singular
`source_contact_allocation_station_pressure_summary` remains an exact
element-zero compatibility mirror. Executable validation rejects mirror drift,
indexed row-derived pressure drift, and non-list or non-object collection
shapes. Review/import adapters prefer the plural collection, preserve exact
indexed review rows plus grouped station, availability, precedence, status,
direction, and reservation evidence, and do not count the mirror twice. Legacy
singular-only artifacts remain accepted and routed. Both paths remain
artifact-only and grant no provider reservation, schedule mutation, Cadence
write, or operator authority.
Campaign-repair V2 likewise preserves
`contact_allocation_reservation_conflict_summary.v1` at
`source_contact_allocation_reservation_conflict_summary`. Its executable path
rejects stale row-derived counts or routes and non-object values; review/import
adapters retain exact conflict rows plus match/status/owner/expiration,
reservation-ID, direction, and station evidence. The preserved summary remains
review-only and cannot reserve provider time, mutate schedules, import into
Cadence, or grant operator authority.
Campaign-repair V2 also preserves every CandidateRefresh
`contact_allocation_capacity_pack_summary.v1` in direct-source-then-canonical
order at `source_contact_allocation_capacity_pack_summaries`, without
deduplication or first-map selection. The existing singular
`source_contact_allocation_capacity_pack_summary` remains an exact element-zero
compatibility mirror, and executable validation rejects mirror drift, indexed
row-derived capacity drift, and non-list or non-object collection shapes.
Operator-review and Cadence adapters prefer the plural collection, retain exact
indexed contact rows and reduced-capacity pack groups with selected/deferred
identity, required-capacity provenance, status, direction, and station
evidence, and do not count the compatibility mirror twice. Legacy singular-only
artifacts remain accepted and routed. Both paths remain review-only with no
provider reservation, schedule mutation, Cadence write, or operator authority.
The validation-reference registry and checked-in
`study_results/contact_allocation_provider_reservation_request_summary_v1.json`
fixture also feed the
`contact_allocation_provider_reservation_request_summary.v1` case directly from
the checked-in artifact. The case
observes provider-reservation request, review, and no-request counts plus
direction routing maps. Fixture verification rejects stale row-derived
request/review/no-request direction maps, including request, review, and
no-request direction/ground-station maps, and it rejects stale reported request
direction maps from the checked-in summary. Schema export pins the
artifact-only model constant, string source boundary, and exact `model_limits`,
so provider-reservation handoff summaries are not treated as provider-write,
schedule-mutation, or operator-authority artifacts.
Operator-review and Cadence-import adapters additionally canonicalize embedded
request/review reservation IDs into sorted unique arrays per match-status route,
preserve keyed empty routes, and publish `uniqueItems` for those route arrays.
Executable validation rejects noncanonical supplied routes while keeping them
independent of provider-reservation contact counts and provider execution.
The compact provider-reservation summary derives those routes from scalar and
list-valued station-calendar reservation identities, so list-only or shared
reservation IDs are not lost. When both contact and reservation route maps are
present, adapters preserve their combined match-status key set with explicit
empty counterparts; handoff validation rejects mismatched key vocabularies but
continues to accept a missing legacy counterpart field.
`study_results/station_calendar_precedence_summary_v1.json` is observed for
applied/overlap availability routing, reserved-under-higher-precedence contact
IDs, unavailable/reserved/reduced-capacity contact ID sets, and artifact-only
no-provider-reservation assumptions. Station-calendar precedence summary schema
export pins the artifact-only model constant and exact `model_limits` used by
generated compact precedence handoff summaries.
`study_results/contact_filter_report_v1.json` is observed for kept/suppressed
candidate counts, row-derived suppressed-candidate counters, duplicate
suppressed-candidate counts, reservation match maps, suppression-reason routing
maps, station availability maps, and model-limit boundaries. Executable
validation rejects stale kept/suppressed counts, invalid contact-input IDs, and
reservation match-status maps that no longer match suppressed candidates,
rejects stale contact-filter model strings, and exports the same model constant
used by generated contact-filter reports. Focused schema-reference coverage also
exact-regenerates the checked-in full report through
`OrbitalDynamics.contact_filter_report/2` from deterministic contact candidates
and declared ground-network rows before schema validation, pinning current
direction, trust-boundary, reservation-match, and suppression-reason routing.
V1 campaign planning now applies that same contact-filter suppression before
contact contention, allocation, link-capacity accounting, ranking, contact
intents, and selected activities are derived, while station-calendar and
contact-suppression handoff rows preserve the suppressed contact evidence for
operator review and Cadence import queues. The full report fixture remains an
artifact-only no-provider-reservation/no-schedule-mutation/no-Cadence-write
handoff.
`study_results/contact_contention_report_v1.json` and
`study_results/contact_contention_resolution_report_v1.json` are observed for
conflict/recommendation counts, row-derived scalar
conflict-group/conflicted-contact/recommendation counters, review-required
counts, operator-action maps, resource-scope routing maps, selected/deferred
contact counts, the recommendation-only no-reservation boundary, and
model-limit boundaries. Executable validation rejects stale contention group,
conflicted-contact, and recommendation counts that no longer match the
contention rows, rejects stale contact-contention model strings, and exports
the same model constant used by generated contention reports. Full contention
reports also pin capability-derived type/direction vocabularies, station
availability metadata, capacity paths, reservation-priority vocabularies,
resolution priority metadata, provider aliases/result keys, identity fields,
and command-contact directions as optional assumptions; stale present metadata
is rejected while omitted capability fields remain compatible. It also rejects
stale contact-contention resolution report model strings and exports the same
recommendation model constant used by generated resolution reports. Resolution
summary validation rejects stale summary model strings plus stale generated
`model_limits`, and exports the artifact-only summary model constant plus exact
`model_limits` used by generated handoffs.
`study_results/contact_contention_resolution_summary_v1.json` fixture now
covers compact conflict/recommendation/review counts, selected/deferred/review
contact routing by group and resource scope, selection-reason/action maps,
model limits, and recommendation-only no-candidate-mutation/no-operator-
authority assumptions. The validation-reference registry and checked-in
`study_results/contact_contention_cross_station_spacecraft_v1.json` fixture
also include a generated cross-station same-spacecraft contention challenge, so
spacecraft-scope contention routing and row-derived resource-scope maps are
checked without provider reservation, schedule mutation, or candidate
suppression.
Campaign-repair V2 preserves that compact artifact at the distinct
`source_contact_contention_resolution_summary` path. Executable validation
rejects stale row-derived counts, identity routes, capacity provenance, or
non-object values. Existing operator-review and Cadence adapters synthesize one
review-gated recommendation per group while preserving compact summary context;
the path performs no candidate selection, provider reservation, schedule
mutation, Cadence write, or grant of operator authority.
Candidate-refresh validation fixtures replay that same generated contention
challenge through source-report provenance, pinning branch-local resource-scope,
direction, contact-ID, and operator-action summaries without performing contact
allocation, candidate selection, import approval, or Cadence writes.
`study_results/link_capacity_report_v1.json` is observed for fixed-rate contact
and selected-contact counts, row-derived scalar contact/selected/evidence
counters, throughput totals, station-selection routing maps, and model-limit
boundaries. Executable validation rejects stale contact/selected counts,
throughput totals, ignored-contact lists that no longer match link rows, and
stale link-capacity model strings; focused schema-reference coverage also
exact-regenerates the checked-in full report through
`OrbitalDynamics.link_capacity_report/3` and verifies absent optional
requirement/actual-throughput/completion fields are not emitted as invalid
present `nil` values. Exported schemas publish the same model constant, string
source boundary, and exact `model_limits` as generated reports. Link-capacity
summary validation rejects stale summary model strings and stale generated
`model_limits`, and schema export pins the artifact-only summary model plus
exact `model_limits` used by generated handoffs. The full report fixture
remains an artifact-only no-link-budget/no-provider-reservation/no-schedule-
mutation/no-Cadence-write handoff.
`study_results/link_capacity_summary_v1.json` now feeds a curated
`link_capacity_summary.v1` validation-reference fixture. The observations check
station/contact/effective/selected/actual-throughput counts, selected and
actual shortfall status, throughput totals, station/contact routing maps, model
limits, and artifact-only no-provider-reservation/no-schedule-mutation
assumptions.
Campaign-repair V2 preserves that compact artifact at the distinct
`source_link_capacity_summary` path. Executable validation rejects stale
row-derived counts, throughput/shortfall totals, station/contact routing, or
non-object values. Existing operator-review and Cadence adapters synthesize a
review-gated row per station while retaining compact source context; the path
performs no scoring, candidate selection, provider reservation, schedule
mutation, Cadence write, or grant of operator authority.
`study_results/relay_data_path_summary_v1.json` is observed for relay/direct
route counts, custody/latency/risk status maps, route IDs, source/relay/station
ID sets, status-routed route ID maps, latency maxima, model-limit boundaries,
and artifact-only no-relay-scheduling/no-custody-delivery assumptions.
Focused schema-reference coverage also regenerates the checked-in fixture
exactly through `OrbitalDynamics.relay_data_path_summary/2` from its checked-in
route rows and source before schema validation, pinning relay/direct row
evidence, generated route ID stability, status routing, latency maxima, model
limits, and the no-scheduling/no-custody-delivery/no-provider-reservation
boundary.
Executable validation rejects stale relay/direct route counts, custody routing,
relay-spacecraft ID sets, latency routing, and generated `model_limits` that no
longer match relay data-path rows, so relay/store-and-forward handoffs cannot
hide stale route evidence behind top-level summaries.
Campaign-repair V2 preserves that summary at the distinct
`source_relay_data_path_summary` path. Full executable validation rejects stale
row-derived route, status, identity, and latency aggregates or non-object
values. Existing operator-review and Cadence adapters route each exact data
path for review while preserving compact source context; the path performs no
repair scoring, candidate selection, relay scheduling, custody delivery,
provider reservation, schedule mutation, Cadence write, or grant of operator
authority.
Station-reservation review, hold, and hold import-readiness summary validation
rejects stale generated `model_limits`, and schema export pins the artifact-only
summary models plus exact StationCalendar `model_limits` used by generated
handoffs. The checked-in
`study_results/station_reservation_review_summary_v1.json`,
`study_results/station_reservation_hold_summary_v1.json`, and
`study_results/station_reservation_hold_import_readiness_summary_v1.json`
fixtures cover expired, active, and missing reservation evidence,
owner/status/action routing, no-provider-reservation review boundaries, and the
hold import-readiness no-provider-write/no-Cadence-write boundary.
The validation-reference registry also observes the checked-in review, hold,
and hold import-readiness summaries as curated fixtures. The review-summary
fixture checks row-derived active/expired/missing expiration maps, reservation
ID routing by expiration status and row type, required review-action counts, and
the no-provider-write boundary. The hold-summary fixture checks row-derived
expiration/status/owner/row-type routing, affected-contact expiration maps, and
the no-provider-write boundary. The import-readiness fixture checks review-only
import classification, row-derived hold import-status and action maps,
reservation ID routing by import status and required action, and the
no-provider/no-Cadence write boundary.
Candidate-refresh station-reservation replay also derives hold
import-readiness status/action/direction routing from compact
`import_readiness_rows` when present, so stale top-level hold import maps cannot
steer branch-local import-review pressure.
The curated CandidateRefresh contact-allocation resource-selection challenge
generates two spacecraft contacts from a real `contact_allocation_report.v1`
allocation path, then supplies a deliberately stale top-level
resource-blocked spacecraft map. Validation observations pin the row-derived
blocked-contact and blocking-dimension maps, the surviving cross-spacecraft
contact, the exact rejected and invalidated contact, allocation report/source
identity, spacecraft scope, and trust-boundary evidence. The corrected source
report remains schema-valid while the stale aggregate copy fails its source
contract, and only the exact row evidence affects CandidateRefresh selection.
The parallel unavailable-resource quality-gate selection challenge generates
two spacecraft contacts and deliberately places both contact IDs under the
`sat_1` blocked scope. It pins rejection and invalidation of only the exact
`sat_1` contact, survival of the `sat_2` contact, quality-gate selection
provenance, and candidate-rejection review/import handoffs. A stale surviving-ID
observation fails reference verification, while the source summary and all
handoff artifacts remain schema-valid and artifact-only.
`study_results/validation_reference_fixtures.json` is refreshed from the
current validation-reference registry, so its fixture IDs and `fixture_count`
track `OrbitalDynamics.Validation.reference_fixtures/0`.

V1 campaign manifests plus V2 repair and V3 strategy request JSON files are
executable request surfaces, not only documentation examples. Use the
deterministic `mix orbital_dynamics.study.run` path for V1 result artifacts and
`OrbitalDynamics.campaign_repair_from_file!/2` and
`OrbitalDynamics.campaign_strategy_from_file!/2` to resolve `source_plan_ref`
and build artifacts from the checked-in request files.
The checked-in V1 result's deterministic planning surface, plus the V2 repair
and V3 strategy artifacts, are pinned in golden tests against those public paths
using the same JSON writer as the generation tasks. Runtime timing fields are
excluded from the V1 equality check, but schema-valid drift in compact planning
examples is caught as fixture drift.
The V2 repair fixture also carries a preserved
`source_candidate_rejection_report` from mission-state evidence. Its golden and
validation-reference checks pin the source report counts plus the derived
operator-review and Cadence-import candidate-rejection rows, so source-report
handoff drift is visible in the public fixture surface.
Executable `campaign_repair.v2` validation also derives
`repair_metadata.timeline_protection` counts and activity IDs from repair
activities and deltas, so stale timeline-protection summaries cannot remain
schema-valid when locked, approved, or executed timeline evidence changes.

For repeatable file-to-file generation, use the campaign run task:

```bash
mix orbital_dynamics.campaign.lint --type repair --request studies/leo_constellation_campaign_repair_v2.json
mix orbital_dynamics.campaign.lint --type strategy --request studies/leo_constellation_campaign_strategy_v3.json --format json
mix orbital_dynamics.campaign.lint --type repair --request studies/leo_constellation_campaign_repair_v2.json --output study_results/campaign_request_lint_v1.json
mix orbital_dynamics.campaign.run --type repair --request studies/leo_constellation_campaign_repair_v2.json --output study_results/leo_constellation_campaign_repair_v2.json
mix orbital_dynamics.campaign.run --type strategy --request studies/leo_constellation_campaign_strategy_v3.json --output study_results/leo_constellation_campaign_strategy_v3.json
mix orbital_dynamics.campaign.run --type strategy --request studies/leo_constellation_campaign_strategy_v3.json --output /tmp/strategy.json --format json
```

`campaign_request_lint.v1` executable validation treats `error_count` as a
non-negative integer and checks it against the emitted error rows, so request
preflight reports match the exported JSON Schema instead of accepting
float-shaped counts. It also derives `status` from `error_count`, so stale
passing/failing summaries cannot drift from emitted diagnostics. The checked-in
repair request lint fixture is compared against a fresh preflight report for
request and source-plan SHA-256 evidence, and executable validation/export both
require lowercase 64-character SHA-256 digests for those evidence fields.
`study_manifest_lint.v1` exports `error_count`,
`warning_count`, and optional `scenario_count` with the same non-negative
integer bounds. The same export also types the `lint_task` and
`semantic_validator` provenance fields as strings, matching the executable
preflight report contract.

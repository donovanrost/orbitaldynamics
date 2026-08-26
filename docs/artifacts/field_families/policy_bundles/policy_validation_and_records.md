# Policy Validation and Records

## Validation Records and Backend Acceptance

Validation records expose typed evidence and known-limit arrays.
`validation_reference_report.v1` and `validation_check.v1` are exported as
standalone contracts for linting individual fixture reports or check rows
without loading the aggregate validation fixture bundle. Top-level
`OrbitalDynamics.validation_registry/0`,
`OrbitalDynamics.validation_record/1`,
`OrbitalDynamics.validation_records_for_result_set/1`,
`OrbitalDynamics.validation_tolerance_policy/0`,
`OrbitalDynamics.backend_acceptance_policy/0`,
`OrbitalDynamics.backend_acceptance_evidence/1`,
`OrbitalDynamics.dependency_policy/0`, and validation-reference fixture facades
expose the same evidence registry, backend package policy, trust policies, and
reference-check helpers for application callers. Study-run backend-selection
metadata embeds backend-acceptance evidence from `backend_acceptance_policy.v1`,
including reference-match and benchmark-artifact requirements for the selected
propagator implementation. The backend policy contract also validates
`known_limits` against `Validation.backend_acceptance_policy/0`, so checked-in
policy artifacts cannot silently drift from the runtime acceptance boundary.
The exported JSON Schema constrains those known limits as an exact string set
as well, making the backend trust boundary machine-readable for non-Elixir
import tooling.
The `result_artifact.v1` and `execution_report.v1`
JSON Schemas expose the nested backend-selection and backend-acceptance evidence
fields under `assumptions`, so downstream gates do not have to treat those trust
fields as an opaque assumptions blob. Executable validation also checks that
top-level backend-selection flags match the nested evidence and that
acceptance-tier requirement booleans match the evidence row.
`refreshed_window.v1` is exported as a standalone executable contract for the
access, target-visibility, and eclipse windows embedded under
`candidate_refresh.v1.refreshed_windows`, with stable window/scenario/target or
ground-station IDs, interval timing, event-detector assumptions, optional
source-window boundary refinement details, and type-specific target or
ground-station evidence.
`source_window_lineage.v1` is exported as a standalone executable contract for
the lineage rows tying refreshed candidate activities back to their source
access, visibility, or eclipse windows, with stable candidate, source-window,
and scenario IDs plus optional nested source-window evidence. Candidate-refresh
lineage rows now include compact nested source-window evidence generated from
the candidate activity, and executable validation cross-checks lineage
candidate IDs, source-window IDs, source-window types, and nested source-window
identity so lineage cannot silently point at a different candidate or window.
`validation_record.v1` is exported as a standalone executable contract for the
model/backend trust rows embedded in candidate refresh artifacts, preserving the
validation level, covered regime, evidence, known limits, implementation, and
optional tolerance map without implying a higher-fidelity regime. The standalone
JSON Schema now exposes `implementation` and `covered_regime` as strings,
matching the executable validation boundary for trust-review imports. Registered
validation record IDs also validate `known_limits` against
`OrbitalDynamics.Validation.registry/0`, and exported JSON Schema mirrors those
registry-bound records with conditional exact known-limit sets while externally
configured validation records remain extensible.

## Validation Reference Fixture Report

`validation_reference_fixture_report.v1` exports nested fixture report and
check rows plus top-level fixture `status_counts`, and each
`validation_reference_report.v1` can expose check-level `status_counts`, so
fixture status, IDs, validation levels, and per-field check results are machine-readable. The checked-in fixture report includes
product-level artifact regressions for campaign V1, repair V2, strategy V3,
and the standalone operator-review import surface.

## Accepted Planning State and Maneuver Execution Delta

`accepted_planning_state.v1` exports a nested spacecraft-state schema for
state-estimate rows: spacecraft/scenario IDs, epoch, frame, Cartesian position
and velocity triplets, source metadata, quality uncertainty triplets, and
OPM/OEM-derived object metadata when present. The standalone and nested
`spacecraft_state_estimate.v1` JSON Schema also types OPM/OEM-derived creation
and originator metadata, spacecraft mass and physical-property fields, covariance
status, and OPM maneuver metadata count/status fields for structural
compatibility. Executable `OrbitData` adapter validation is the source of
truth for covariance completeness, exact frame/epoch/unit binding, and numerical
support; the generated JSON Schema remains an extensible compatibility and
structural schema, was not broadened by Slice A, and currently types only the
narrower covariance fields that are actually present in the checked schema.
`spacecraft_state_estimate.v1` is also exported as a standalone executable row
contract for linting individual accepted state vectors outside a full
planning-state snapshot. Executable validation and JSON Schema require
standalone and nested spacecraft-state estimates to declare a direct
`trust_boundary` or `provenance.trust_boundary`; orbit-data adapters inherit the accepted
planning-state import trust boundary onto state-estimate rows when a row does
not declare its own provenance.
The top-level `accepted_planning_state.v1` JSON Schema also exposes the import
provenance trust gate: if artifact provenance declares an input format, import
adapter, provider, adapter, or adapter version, `provenance.trust_boundary` is
required just as it is in executable validation.
`maneuver_execution_delta.v1` is likewise exported as a standalone executable
row contract for accepted maneuver status deltas, preserving activity identity,
status, source, quality, trust-boundary provenance, and optional epoch or
delta-v evidence. Its exported JSON Schema now types OPM `MAN_*` source fields,
metadata-only maneuver status, duration, delta-mass, maneuver reference-frame,
and no-propagation metadata so import adapters can inspect those fields without
falling back to generic objects. Executable validation and JSON Schema require
standalone and nested maneuver-execution deltas to declare a direct
`trust_boundary` or `provenance.trust_boundary`; orbit-data adapters
inherit the accepted planning-state import trust boundary onto metadata-derived
deltas when the delta does not declare its own provenance. Simple JSON,
OPM, OEM, and TLE metadata preflight adapters stamp provenance with `input_format`,
`import_adapter`, `trust_boundary: external_orbit_data_adapter`, and
`network_access: false` so downstream artifacts can audit the import boundary
without trusting unstated adapter behavior.
Executable accepted-planning-state validation enforces that convention for
imported artifacts: if provenance declares `input_format`, `import_adapter`,
provider, adapter, or adapter-version metadata, it must also declare
`provenance.trust_boundary`.
The OPM adapter preserves
`CCSDS_OPM_VERS`, `CREATION_DATE`, `ORIGINATOR`, `OBJECT_NAME`, `OBJECT_ID`,
`CENTER_NAME`, `REF_FRAME`, `TIME_SYSTEM`, `MASS`, `DRAG_AREA`, `DRAG_COEFF`,
`SOLAR_RAD_AREA`, and `SOLAR_RAD_COEFF` as planning provenance,
exports `MASS` and the physical
metadata fields from accepted planning-state metadata, imports and exports
complete frame/epoch-bound OPM covariance matrix terms as
`covariance_matrix_6x6` metadata-only evidence with component order, closed exact
canonical CCSDS units, deterministic normalized numerical support evidence, and
explicit no-propagation status, and preserves one or more repeated OPM
`MAN_*` maneuver metadata blocks as `maneuver_execution_delta` rows without
applying maneuver propagation. OPM export uses preserved `CREATION_DATE` and
`ORIGINATOR` metadata when explicit export overrides are not supplied and writes maneuver-execution deltas that
carry an epoch and three-component delta-v vector back to repeated `MAN_*`
metadata blocks, preserving duration, delta-mass, and maneuver reference-frame
metadata when present while still applying no maneuver propagation. Standalone
`maneuver_execution_delta.v1` rows can
be normalized directly through `OrbitalDynamics.operator_review_package/1` and
`OrbitalDynamics.cadence_import_manifest/2`; without planned maneuver context
they are treated as `realized_only` maneuver feedback and routed to
`review_unplanned_realization` / `review_realized_feedback` while preserving the
original delta under `source_feedback`. The OEM adapter preserves the same header/object/frame/time
metadata plus the selected ephemeris sample index and epoch, imports a single
complete OEM covariance block as `covariance_matrix_6x6` metadata-only evidence
with component order, closed exact canonical CCSDS units, exact selected-sample
coepoch text binding, frame binding, deterministic normalized numerical support
evidence, and explicit
no-propagation status, and can
export a single accepted state as a single-sample OEM KVN handoff with explicit
no-interpolation metadata plus a metadata-only covariance block when accepted
state quality carries a complete locally validated covariance matrix; OEM export
also uses preserved `CREATION_DATE` and `ORIGINATOR` metadata unless callers
override them. OPM and OEM covariance are preserved only as planning metadata and
do not drive propagation, both adapters reject duplicate single-value KVN fields,
partial/mismatched covariance declarations, and covariance export override
conflicts instead of silently overwriting or attaching them, and OEM
import/export does not interpolate between samples.
The public `OrbitalDynamics.import_ccsds_opm/2`,
`OrbitalDynamics.import_ccsds_oem/2`,
`OrbitalDynamics.export_orbit_data_json/1`,
`OrbitalDynamics.export_ccsds_opm/2`, and
`OrbitalDynamics.export_ccsds_oem/2` facades expose those accepted-state
interchange paths without requiring callers to depend on
`OrbitalDynamics.OrbitData` directly.
`OrbitalDynamics.inspect_tle/2` and `OrbitalDynamics.inspect_ccsds_omm/2`
expose the metadata-only mean-element preflight paths.

## TLE and OMM Metadata Preflight

TLE inputs are metadata-only at this boundary. `OrbitData.inspect_tle/2`
validates two-line element checksums and catalog-number consistency, returns
object/orbital-element metadata including mean-motion derivatives and BSTAR
drag metadata, derives mean-element period, semi-major axis, perigee/apogee
altitude, and coarse altitude-regime metadata for triage, and marks the record
as requiring an `sgp4` propagation regime rather than emitting
`accepted_planning_state.v1`. Those derived altitude fields are preflight
estimates from TLE mean elements, not propagated Cartesian state. The
preflight is intentionally single-object: multi-object TLE drops are rejected
as ambiguous input instead of silently selecting the first object.
CCSDS OMM inputs follow the same metadata-only boundary.
`OrbitData.inspect_ccsds_omm/2` parses narrow OMM KVN mean-element metadata,
rejects duplicate single-value fields, preserves object/catalog/frame/time-system
and declared `MEAN_ELEMENT_THEORY` metadata, derives mean-element period,
semi-major axis, perigee/apogee altitude, and coarse altitude-regime triage,
and marks the record as not compatible with `accepted_planning_state.v1`.
`OrbitalDynamics.import_orbit_data/2` rejects OMM wrappers with the parsed
metadata attached, so adapters get review evidence without silently converting
mean elements into Cartesian planning state.

## Station Calendar Provider

`station_calendar_provider.v1` exports a nested entry schema for declared
ground-network availability/capacity intervals, including station identifiers,
availability/status values, direction aliases, timing fields, optional capacity
fraction, entry-level trust/provenance, and reservation metadata. Runtime
provider and raw ground-network normalization
also accept numeric `availability` as a capacity-fraction alias before
refreshed downlink throughput/scoring, canonicalize provider-shaped nested
station identity, parse clean station-window timing aliases before overlap
selection, and treat availability-only `maintenance` rows as unavailable station
time, matching contact-filter and V3 branch-derived ground-network semantics. Provider inputs
must declare a trust boundary either as `trust_boundary` or
`provenance.trust_boundary` before import-gate validation accepts them, and
normalized affected-contact rows preserve the provider provenance and trust
boundary for review/import queues.
`station_calendar_report.v1` affected-contact rows carry
`station_calendar_trust_boundary_status`, and the report summarizes those rows
in `station_calendar_trust_boundary_status_counts`, so review/import consumers
can distinguish declared provider boundaries from missing provenance without
reopening nested entries.
Applied affected-contact `contact_success_factor` and `command_success_factor`
values use the same unit-interval confidence contract as policy decision
evidence before those rows flow into operator-review or Cadence-import queues;
out-of-range confidence is preserved as invalid feedback evidence on the
station-calendar review/import row instead of being clamped into policy
context.
`station_calendar_report.v1` affected-contact rows also carry
the applied highest-priority calendar entry plus the full overlapping entry ID
and availability set, so reserved time does not hide concurrent reduced-capacity
or maintenance context in review packages. When multiple overlapping entries
tie at the highest priority, the row uses a stable synthetic ambiguous
calendar-entry ID and carries `station_calendar_ambiguous_entry_ids` instead of
choosing arbitrary capacity, reservation, or provider-entry metadata.
Candidate-refresh downlinks use the same ambiguous calendar semantics when
building refreshed contacts: ambiguous reduced-capacity inputs remain
non-suppressing without selecting one capacity value, while ambiguous
unavailable or reserved inputs are suppressed with the ambiguous entry IDs and
reservation lists preserved for allocation and review rows.
Reservation overlaps also carry
reservation ID, owner, and status lists independent of the applied entry, so
operator review can still route an outage-affected contact through reservation
overlap review when declared reserved time also overlaps. Contact-allocation
approval context preserves the same applied reservation ID, owner, status, and
overlap lists so policy decisions archive the exact declared reservation
boundary. When supplied an approval policy, affected-contact rows also carry
`approval_requirements`, approval-rule matches, and `policy_decision.v1`
evidence for unavailable, reserved, or severely reduced-capacity station
boundaries.

## Standalone Window, Candidate, and Invalidated Contracts

`remaining_horizon.v1` is exported as a standalone executable contract for the
planning window used by repair and candidate-refresh artifacts, with interval
ordering validation and optional output-step cadence.
`candidate_activity.v1` is exported as a standalone executable contract for the
same observe/downlink candidate rows embedded in `candidate_refresh.v1`, with
stable IDs, timing, score terms, source-window provenance, schema-visible
spacecraft/collection/payload/instrument/product identity, optional observation
feedback evidence, optional contact handoff fields, and reusable
`activity_context` carrying stable activity/timeline identity for downstream
review and import artifacts. Promoted objective/resource fields now validate
stable IDs plus non-negative latency, observation, and downlink-demand
quantities at the standalone candidate-activity boundary. Target-observation,
target-revisit, target-coverage, priority-commitment, and urgent-target objectives in a
candidate-refresh request can now add deterministic
`observation_objective_*`, `required_observations`, and
`observation_objective_value` score-term evidence to matching observation
candidate rows, including when objectives route by nested `target` objects or
target-object lists and nested `spacecraft` / `satellite` selector identity,
with the same objective context copied into
`activity_context` for review/import routing. Urgent/priority observation
objectives can also raise a refreshed observation's `target_priority`, with
`target_priority_source` and `target_priority_objective_ids` preserving the
objective evidence that changed the target-value score. Collection-latency
objectives now also annotate matching observation candidates with
`collection_latency_objective_*`, collection/product/payload/instrument
identity, including nested provider `collection`, `product`, `data_product`,
`products`, `payload`, and `instrument` selector objects normalized to
canonical ID fields, plus `max_latency_s`, `required_downlink_mb`, and
`collection_latency_observation_value` evidence, so the observation that
creates latency-sensitive data is traceable to the generated downlink demand.
For broad product selector lists, the singular `product_id` reflects the
matched observation product while `product_ids` preserves the full selector set.
Candidate
activity `source_window` maps expose
event timing policy, interpolation/refinement labels, and optional boundary
detail maps when the source detector provides them; executable validation
checks nested source-window identity, source-window type labels, boundary
interpolation fractions, sample indices, and eclipse sun-vector shape.
Reusable `activity_context` maps also carry candidate observation lighting and
eclipse-overlap evidence plus source-window and command-window type labels, so
timeline diffs, operator-review rows, and Cadence-import manifests can route
lighting, source-window, or command-window provenance changes without embedding
whole candidate rows. When a
nested `source_window` map is carried in activity context, it uses the same
typed source-window boundary-detail validation as candidate activity source
windows while admitting explicit evidence markers for candidate-derived,
operator-supplied, and unvalidated urgent-placeholder strategy inputs.
Standalone candidate activity contact and
observation success factors are bounded to the same unit interval used by the
downstream review, policy, and import artifacts. Standalone candidate activity
duration and eclipse-overlap fields export as typed number properties, and
lighting-condition/detail/model/confidence fields export as typed enum string
properties matching the embedded candidate-refresh row shape. Planned activity
exports type fixed-rate aliases such as `data_rate_mb_s`,
`downlink_rate_mb_s`, and `downlink_rate_mbps`, so planned contact/downlink
rows lint the same rate evidence later compared in timeline feedback. Known nested
`throughput_model` fields are also executable contract fields: estimated,
planned, required, actual, delivered, and received MB aliases must be numeric
and non-negative, while station capacity and throughput/confidence factors are
bounded to the unit interval. Unknown provider extension keys remain allowed.
`invalidated_candidate.v1` is likewise exported as a standalone row contract so
replacement IDs, source-window IDs, semantic change reasons, and budget-dropped
match evidence can be linted outside the full candidate-refresh artifact.
Standalone invalidated-candidate rows can be normalized directly through
`OrbitalDynamics.operator_review_package/1` and
`OrbitalDynamics.cadence_import_manifest/2` into `candidate_diff_review` and
`review_candidate_diff` gates.

## Environment Model and Capability Catalog

`environment_model_capability.v1` and `environment_provider_capability.v1`
export typed `model`, `source`, `supported_bodies`, and `known_limits` fields so provider
capability records are less dependent on untyped generic fallbacks. Environment
provider capability rows also expose optional `outputs`, `parameters`,
`trust_boundary`, and `provenance` fields in JSON Schema. Rows with
`network_access: true` must declare `trust_boundary` directly or through
`provenance.trust_boundary`, keeping future external ephemeris or
Earth-orientation adapters behind an explicit trust boundary. Built-in
environment model and provider IDs now also validate `known_limits` against
`Environment.model_capabilities/0` and `Environment.provider_capabilities/0`,
and exported JSON Schema mirrors that with conditional exact known-limit sets
for those built-in IDs while externally configured IDs remain extensible. The
built-in provider set now includes a declared-sample Earth-orientation table
adapter for body-fixed ground-track analysis and a reference exponential
atmosphere-density provider consumed by the standalone drag evaluator and
programmatic-only scalar two-body-drag propagator. Study manifests can declare
the tabular provider under
`ground_track_crossings[].earth_rotation_provider`, and result artifact
ground-track rows preserve the provider ID, model, rate, interpolation label,
and before/after rotation angles used for the body-fixed crossing.
Top-level
`OrbitalDynamics.fixed_sun_direction/2`,
`OrbitalDynamics.constant_earth_rotation/1`,
`OrbitalDynamics.validate_environment_model_capability/1`,
`OrbitalDynamics.environment_model_capabilities/0`,
`OrbitalDynamics.environment_provider_capabilities/0`,
`OrbitalDynamics.validate_environment_provider_capability/1`, and
`OrbitalDynamics.environment_provider_covers_time_span?/2` expose the same
model and provider-capability inspection boundary without requiring callers to
depend on internal provider modules. `OrbitalDynamics.environment_provider_supports_request?/2`
checks the same provider record against a requested time span, body, and
output/product so adapter selection can reject unsupported products before a
network-backed provider is ever invoked, and
`OrbitalDynamics.environment_provider_capabilities_for_request/1` returns the
matching provider capability records for that request. Earth-rotation providers
declare the product-level `earth_rotation` output alongside
`earth_rotation_angle_rad` and `earth_rotation_rate_rad_s`, so callers can select
by product or by scalar field. `OrbitalDynamics.capability_catalog/0`
also exposes those model and provider records alongside the declared analysis,
planning, operations, constraints, validation, reporting, and review capability
metadata, including a `analysis.propagators` map for the scalar, Nx, and EXLA
propagator backends plus search-generator, artifact-metric constraint,
executable schema-registry, result-set report, and study-benchmark report
capability surfaces. The `validation.schema` record gives adapter preflight
code the sorted executable artifact contract list, contract count, JSON Schema
draft, compatibility-policy version, identity-policy version, validation-report
contracts, and schema-validation known limits without exporting the full schema
bundle. `OrbitalDynamics.capability_catalog_artifact/0` and
`mix orbital_dynamics.capabilities --format json` expose that discovery payload
as `capability_catalog.v1`, so automation can schema-lint the catalog before
using it for adapter preflight checks.
`OrbitalDynamics.task_chunking_recommendation/2` and
`OrbitalDynamics.resolve_task_chunk_size/2` expose the deterministic chunk-size
policy used when `run_study/2` receives `task_chunk_size: :auto`, allowing
callers to preview distributed task batch sizing before a run.

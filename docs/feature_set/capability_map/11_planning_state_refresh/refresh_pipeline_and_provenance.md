# Refresh Pipeline and Provenance

## Candidate generation sources

- **V1** can generate candidate observations and downlinks from a study result.
- **V2** and **V3** can reuse candidate windows carried by prior campaign or repair artifacts.

## Refresh inputs and core regeneration

`candidate_refresh.v1` manifests can start from:

- an `accepted_planning_state.v1` snapshot, or
- a simple `candidate_refresh.orbit_data` state-estimate batch.

From those inputs the pipeline:

- Propagates accepted spacecraft states.
- Regenerates access, target-visibility, and eclipse windows.
- Builds refreshed candidate activities.
- Filters resource- and ground-network-unavailable candidates.
- Marks stale prior candidates.
- Emits freshness metadata for accepted snapshot age and horizon alignment.

### Opt-in executable Level 5 bundle

`CandidateRefresh.run/2` is the executable entry point for the single fixed
bundle `candidate_refresh.earth_j2_drag_access_eclipse.v1`. The existing
`CandidateRefresh.build/2` result-set composition path is unchanged. The
executable path accepts a direct, schema-valid `accepted_planning_state.v1`
with exactly one matching spacecraft state and rejects indirect, missing,
multiple, mismatched, maneuver-bearing, or non-Earth/ECI-J2000/TDB inputs. Its
horizon must start at the current state epoch, be positive and no longer than
24 hours, and declare a 10-second output cadence.

Before any propagation, `ExecutionPolicy.capture/1` freezes a lossless,
JSON-safe policy document containing:

- explicit dry mass, propellant mass, drag area, and drag coefficient;
- one explicit spherical ground-station geometry;
- Earth central-body constants and the fixed J2/drag RK4 10-second model;
- built-in exponential-atmosphere and constant-Earth-rotation capabilities,
  revisions, and coverage;
- a fixed +X ECI Sun direction;
- spherical access with bracketed bisection at `1.0e-6` seconds and at most 64
  iterations, plus cylindrical-eclipse linear interpolation;
- the loaded BEAM module-version digests for the explicit capture, scenario
  construction, propagation, force-model, vector/epoch/frame, access-geometry,
  event-timing, and eclipse execution graph;
- an explicit module allowlist, offline execution mode, `network_access:
  false`, and the bundle's model limits.

Public policy and snapshot values are recursively checked before capture. Only
finite JSON scalars, proper lists, and plain maps with UTF-8 binary or atom keys
are accepted. Atom keys are normalized losslessly; duplicate atom/string keys,
semantic aliases, structs, PIDs, functions, references, non-byte-aligned
bitstrings, improper lists, arbitrary tuples, unsupported keys, and non-finite
or excessive values are rejected. Canonical SHA-256 fingerprinting runs only on
that validated normalized form and never uses inspected runtime text as
identity material. Normalization is also bounded before semantic validation to
32 nested levels, 10,000 entries per collection, 512 bytes per key, 1 MiB per
binary, 100,000 visited terms, and 4 MiB of cumulative binary/key byte work;
limit failures carry the offending path and limit rather than traversing an
unbounded value. The candidate-refresh artifact contract applies the same
bounded traversal as a whole-artifact preflight before collection or arithmetic
validation, including atom/string collision and improper-container rejection.
Canonical persisted nullable fields use `:null`, which the repository OTP
`:json` stack round-trips as JSON null. Public construction normalizes nullable
`nil` values to `:null` before policy fingerprint and refresh-ID construction;
persisted policy and whole-artifact validation reject noncanonical `nil`
instead of silently repairing it. Produced executable-refresh artifacts contain
no persisted `nil` and round-trip through `:json.encode/1` and `:json.decode/1`
without changing the policy fingerprint, either refresh-ID surface, or semantic
validation. Boolean values remain booleans.

After capture, the runner does not dynamically dispatch caller-selected
modules or reread configuration, source, campaign, or network providers. It
builds one ballistic `Scenario` and calls `J2Drag.propagate_captured/3` with the
serialized atmosphere and Earth-rotation capabilities and revisions. `J2Drag`
calls the canonical `ExponentialAtmosphereProvider.fetch_captured/3` evaluator
directly; that is the single exponential-density equation, and neither API
rediscovers capabilities or configuration on the captured path. The runner
checks every digest in the single explicit executable-module allowlist
immediately before and after every post-capture execution stage. That allowlist
includes the transitive `J2`, `AtmosphericDrag`, `AccessGeometry`,
`EventTiming`, and construction helpers consumed by the fixed runner, rather
than only its four entrypoint modules. A mismatch returns a typed
`execution_policy_drift` failure and discards all stage output. The runner then
regenerates access and eclipse events and assembles an in-memory `ResultSet`.

Before calling the unchanged `Build.build/2`, the runner injects the serialized
policy and detector evidence under the reserved
`candidate_refresh_execution_policy` and `candidate_refresh_execution_evidence`
model-assumption keys. After the unchanged legacy builder returns, the
executable runner restores those exact canonical documents and derives the
executable refresh ID from the same pre-encoding refresh input through
`BuildRefreshId`; this prevents the legacy atom stringifier from changing the
canonical `:null` identity representation. The policy retains the exact
normalized refresh-identity input, while the evidence binds scenario/station
identity, trajectory sample count, canonical access/eclipse digests, and the
exact candidate source-window projection derived from access evidence. State,
ballistics, station geometry,
provider/detector revisions and BEAM digests, fixed model settings, and
generated window evidence therefore participate in the existing refresh ID.
Equivalent input order and the same `generated_at` are deterministic.

Only regenerated ground-station access produces downlink candidates. Eclipse
intervals are archived under refreshed windows and do not create candidates.
The nested `candidate_refresh_execution.v1` report binds bundle, execution
mode, policy fingerprint, refresh/study/snapshot/spacecraft/scenario/station
identity, detector evidence, generated counts, selected policies, model limits,
and Domain 18 case
`orekit_13_1_7_leo_j2_drag_access_eclipse` with validation scope
`exact_case_only`. This branch references that case but does not claim or run
the final exact external-truth integration; that gate remains pending the
Domain 18 merge.

Every execution stage returns a typed
`candidate_refresh_execution_failed` error. Failures return no partial
artifact, while zero-event and zero-candidate executions remain valid. The
final artifact is executable-validated, including the captured policy,
fingerprint, recomputed trajectory count and `BuildRefreshId`, four-way snapshot
identity, scenario/station window identities, deterministic window IDs and
boundaries, candidate/source-window causality, detector digests, policy-copy,
exact-case, and model-limit bindings. Persisted policy validation applies the
same body/frame/time-scale/epoch/horizon and identity-alias conflict rules as
live input validation, including every fixed module/evaluator surface and
secondary module alias, so a contradictory policy remains invalid even if its
fingerprint, detector digests, and both refresh-ID surfaces are recomputed.

## Candidate-set diff and matching

- Emits **occurrence-aware** candidate-set diff explanations that do not collapse duplicate prior/refreshed candidate IDs.
- Flags ambiguous semantic prior/replacement candidate matches instead of choosing arbitrary replacement links.
- Preserves malformed prior candidate rows missing or carrying invalid stable identity, scenario identity, source-window/station-calendar identity, or activity type as **sanitized invalidated-candidate review evidence** instead of matching them semantically.
- Records candidate-diff semantic changes when retained or semantically matched candidates differ only by throughput, contact-success, observation-success, target-priority, station availability, station capacity, or reservation context.
- Candidate-diff and candidate-rejection report scalar counts export and validate as non-negative integers.

## Contact allocation and filtering

- Embeds a `contact_allocation_report.v1` over refreshed contact candidates for allocated/deferred/blocked branch-refresh review, with optional allocation policy decisions over post-resource-filter contacts plus contact-filtered blocked rows.
- Keeps only effectively allocated contacts in final `candidate_activities` and `contact_intents`.
- Reuses the shared contact/resource filter modules so refresh `approval_policy` evidence is preserved on embedded contact and resource suppression rows.

### Station-calendar trust and provider overlays

- Contact-filtered station suppressions preserve declared-or-missing station-calendar trust-boundary status and source provider-calendar evidence.
- `station_calendar_provider.v1` inputs are normalized directly into the same refresh-local ground-network overlays for contact filtering and allocation.
- Generated downlink candidates whose station capacity or availability comes from ground-network overlays carry the same trust-boundary status and source calendar evidence.

## Operational feedback application

### Throughput and success feedback

- Applies standalone `operational_feedback.station_throughput_factor` to generated downlink throughput.
- Preserves contact-success feedback factors and source labels on generated downlink candidates.
- Applies standalone observation-success and target-priority feedback to generated observations.
- Applies resource-margin and payload/antenna-availability feedback overlays into the refresh-local `resource_summary.v1` rows used by the same thin resource filter, **without double-applying** V3 branch target feedback already encoded into target rows.

### Capability metadata and trust boundaries

- Declares V1 capability metadata and known limits.
- Preserves source-window lineage.
- Classifies standalone operational-feedback trust boundaries in candidate-refresh provenance as `declared` or `missing`.
- Warns when scoring/filtering feedback is applied without a declared trust boundary, while preserving that warning's structured feedback trust context in operator-review and Cadence import rows.

### Malformed and invalid feedback handling

- Preserves malformed non-object `operational_feedback` inputs as invalid feedback warning provenance instead of raising during candidate generation.
- Drops malformed scalar feedback entries — such as non-numeric contact-success, station-throughput, downlink-demand, and target-priority values, plus negative downlink-demand or target-priority values — from effective branch refresh, while preserving the rejected entries as invalid feedback provenance.
- Drops malformed nested resource-margin, resource-availability, or downlink-demand-source feedback sections from filtering/scoring while preserving them as invalid feedback provenance.
- Rejects non-stable station/target/activity/spacecraft keys from effective operational-feedback maps while preserving those invalid keys as provenance sections.
- Preserves malformed provider-shaped `operational_feedback.realized_activities` identities as invalid realized-row feedback provenance while still applying valid realized rows.

### Availability alias merging and canonicalization

- Merges the legacy `availability_overrides` alias with canonical `resource_availability_overrides` before resource filtering, so empty canonical maps do not hide adapter-supplied alias entries.
- Canonicalizes struct-style `payload_available?`, `antenna_available?`, and `degraded?` flags, trimmed case-insensitive `"true"`/`"false"` availability strings, plus `storage_capacity_margin`, `downlink_capacity_margin`, `battery_soc`, and battery state-of-charge before resource filtering.
- Applies mode/degraded and spacecraft-unavailable availability feedback to refresh-local resource summaries before the shared resource filter runs.

## Pre-filter feedback replay from prior reports

### Resource projection and resource-filter reports

- Emits source `resource_projection_report.v1` storage, downlink, battery, payload, antenna, spacecraft, and degraded pressure rows as the same resource-margin/availability feedback before filtering, including rows preserved in operator-review packages and Cadence-import manifests while retaining report or row trust-boundary evidence.
- Replays prior `resource_filter_report.v1` suppression rows from direct source reports, result-artifact wrappers, operator-review packages, and Cadence-import manifests as resource-margin/availability feedback before regenerated candidates are filtered.

### Contact-filter reports

- Replays prior `contact_filter_report.v1` station suppressions from the same direct, wrapped, review, and import surfaces as ground-network unavailable/reserved/zero-capacity station intervals before regenerated contacts are filtered, while preserving contact-filter source report provenance, suppression reason counts, invalid contact input counts, and trust-boundary evidence.

### Unavailable-resource readiness, quality-gate, and contact-allocation evidence

- Applies schema-valid blocked `quality_gate_report.v1` or
  `operational_readiness_report.v1` evidence to any regenerated candidate only
  when the report is scoped to `planned_activity.v1` and its non-empty
  `source_artifact_id` exactly equals the candidate ID. Aggregate blocked
  status, generic compact summaries, gate-row IDs, nonmatching source IDs,
  malformed reports, and review-only, analysis-only, or passed reports remain
  provenance-only.
- Applies direct, accepted-state, mission-state, and result-artifact-wrapped
  `operational_readiness_report.v1`
  `evidence.resource_blocked_contact_ids_by_spacecraft_id` maps and
  `operational_quality_gate_unavailable_resource_summary.v1` evidence to
  regenerated contact selection only when an exact candidate contact ID is
  listed under that candidate's spacecraft identity in the respective
  blocked-contact map.
- Applies canonical `contact_allocation_report.v1` rows carrying
  `source_resource_suppression` through the same exact candidate-ID and
  spacecraft-identity boundary. The filter derives contact and spacecraft
  scope from the row; stale top-level resource-blocked maps are not selection
  inputs. Operator-review and Cadence-import round trips retain the embedded
  row status, scope, blocking dimension, suppression, and resource trust, with
  wrapper-qualified source paths in the rejection evidence.
- Readiness reports with only aggregate resource pressure and no explicit
  blocked-contact map do not emit a selection-time rejection report. Aggregate
  quality-summary reasons, pressure counts, blocking-dimension maps, and contact
  IDs scoped to another spacecraft do not suppress candidates; an explicit map
  can still yield a zero-rejection explanation of the evaluated set.
- Emits `candidate_rejection_report.v1` rows for the evaluated candidate set,
  preserving readiness, quality, or contact-allocation source paths,
  artifact/report identity, exact candidate scope, resource blocking dimension,
  spacecraft scope, and trust evidence. Matching prior candidates are
  invalidated with source-specific reasons, and the existing
  operator-review/Cadence-import handoff remains review-only.

### Station-calendar reports

- Replays prior `station_calendar_report.v1` affected-contact rows from direct source reports, result-artifact wrappers, operator-review packages, and Cadence-import manifests as the same unavailable, reserved, and zero-capacity pre-filter station feedback, while preserving calendar-entry, reservation, source-review, source-path, provenance, and trust-boundary evidence — including wrapper trust boundaries inherited by nested operator-review packages or nested Cadence-import manifests when reconstructed review rows omit row-level trust.
- Replays prior `station_calendar_report.v1` provider-calendar contention groups from the same direct, wrapped, review, and import surfaces as branch-local reserved/unavailable/zero-capacity station intervals derived from their source calendar entries, preserving source provider entries, provider IDs, provider-entry IDs, reservation IDs, owner/status lists, directions, provenance, and trust-boundary evidence, and keeping provider-specific contention status flattened on the generated contact-filter suppression row instead of collapsing it to a generic reserved-overlap label.

### Contact-intent rows

- Replays prior `contact_intent.v1` rows from direct source intents, result-artifact wrappers, operator-review packages, and Cadence-import manifests as the same unavailable/reserved/zero-capacity pre-filter station feedback, while preserving contact-intent policy, reservation, timing, and trust-boundary evidence — including wrapper trust boundaries inherited by embedded contact-intent rows from direct wrappers, nested operator-review packages, or nested Cadence-import manifests when those rows omit row-level trust.
- Compact `contact_intent_summary.v1` source inputs with embedded rows derive
  CandidateRefresh source-report and replay direction/capacity routing from the
  rows before summary aggregates are merged, preventing stale top-level maps
  from hiding row-local contact-intent pressure.

## Downlink-completion objectives from prior reports

- Converts prior `contact_contention_resolution_report.v1` deferred downlink recommendations from direct source reports, result-artifact wrappers, operator-review packages, and Cadence-import manifests into downlink-completion objectives while preserving selected/deferred contact and source-window evidence.
- Summarizes direct, result-artifact-wrapped, operator-review, and Cadence-import `contact_contention_report.v1` inputs with conflict-group, invalid-contact-input, resource-scope, required-action, path, and trust-boundary counts **without mutating candidate selection**.
- Converts prior `contact_allocation_report.v1` deferred, blocked, or policy-blocked downlink rows, plus prior `link_capacity_report.v1` selected or actual downlink shortfall rows, from direct source reports, result-artifact wrappers, operator-review packages, and Cadence-import manifests into downlink-completion objectives before regenerated downlinks are scored.
- Compact `link_capacity_summary.v1` inputs with embedded rows derive
  CandidateRefresh source-report and replay throughput, selected/actual contact,
  source-window, and direction-routing maps from rows before stale top-level
  summary aggregates are merged.
- Compact `relay_data_path_summary.v1` inputs with embedded rows derive relay
  and direct route counts, route/status maps, spacecraft IDs, and ground
  downlink contact IDs from rows before stale top-level summary aggregates are
  merged.

## Result-artifact wrapper handling

Standalone candidate-refresh result-artifact wrappers accept canonical and adapter-facing `source_*_report` keys for:

- objective, constraint, score, resource, link, allocation, contention, and filter reports; plus
- passive candidate-diff, candidate-rejection, freshness, refresh-budget, schema-validation, operational-readiness, and validation-safety-case provenance reports, including validation-safety-case branch-pressure summaries for blocked/review-required evidence.

Additional wrapper behaviors:

- List-valued embedded report keys whose indexed source paths and inherited wrapper trust boundaries are retained in provenance.
- Embedded `refresh_budget_report.v1` payloads are executable-validated through the refresh wrapper, so input/kept/dropped count mismatches cannot hide inside `candidate_refresh.v1`.
- `candidate_rejection_report.v1` rows can be replayed as refresh-scoped candidate-rejection review/import handoff rows.
- Nested operator-review packages or Cadence-import manifests inside those wrappers inherit the same wrapper trust boundary before review/import rows are reconstructed into source reports.

## `provenance.source_reports` summaries

Summarizes the following source inputs under candidate-refresh `provenance.source_reports`:

- timeline-feedback, operational-timeline, timeline-diff, timeline-transition-application, command-window, maneuver-review, constraint, objective-satisfaction, objective-tradeoff, score-term, station-calendar, contact-contention, contact-contention-resolution, contact-allocation, link-capacity, candidate-rejection, provider-counteroffer, schema-validation, quality-gate, model-acceptance, validation-safety-case, and operational-readiness sources.

Each summary carries paths plus its relevant counts/summaries:

- **Counts and statuses** — row/recommendation counts, status or reason counts, provider counteroffer cost/lock-deadline summaries.
- **Timeline** — timeline-diff status, required-action, duplicate-scope, and feedback counts; timeline-transition application status, decision, action, and duplicate-scope counts.
- **Windows and maneuvers** — command-window feedback counts; maneuver-review feedback and uncertainty counts.
- **Constraints and resources** — constraint metric/resource/spacecraft routing counts; resource-projection pressure type, spacecraft, and activity routing counts; resource-filter spacecraft/resource/blocking-dimension routing counts.
- **Contacts** — contact-contention ground-station/contact routing counts; candidate-rejection candidate/station routing counts; link-capacity ground-station and selected/actual contact routing counts, with compact link-capacity and relay data-path summaries deriving those maps from embedded rows when present.
- **Objectives and scoring** — objective/score-term station, target, and collection routing counts.
- **Allocation** — contact-allocation station-pressure contact counts by ground station, station availability, precedence availability, and precedence rank.
- **Station calendars** — station-calendar affected-contact counts by ground station and availability; station-calendar provider-contention counts by provider and ground station.
- **Contact filter/intent** — contact-filter station-suppression counts by ground station, availability, and status; contact-intent station-feedback and status count maps, plus row-derived compact-summary direction/capacity routing when embedded contact-intent rows are present.
- **Quality gates and readiness** — quality-gate row/status/classification count maps derived from quality-gate rows when rows are present; readiness and quality-gate Cadence-import gate import-status/freshness/schema-validation count maps.
- **Adapter boundary** — adapter-boundary declared/missing/untrusted count maps.
- **Counteroffers** — provider-counteroffer status/action/cost/lock-deadline summaries.
- **Freshness and budget** — freshness status/reason summaries; refresh-budget kept/dropped/limit summaries.
- **Schema validation** — schema-validation status/contract/mode count maps.
- **Model acceptance** — model-acceptance intended-use and validation-level counts, plus model-ID routing maps by acceptance status, validation level, and intended use.
- **Validation safety case** — validation-safety-case status/evidence counts plus evidence-reference maps by status and input contract, with executable artifact validation rejecting malformed safety-case count and evidence-reference routing summaries.
- **Readiness routing** — readiness review-type/import-action/source-review-type count maps.
- **Feedback context** — operational-feedback input keys, and trust-boundary evidence.

### Inspection helpers

Callers can also use `CandidateRefresh.source_report_summary/1` or
`OrbitalDynamics.candidate_refresh_source_report_summary/1` to inspect the same
normalized source-report provenance from a refresh request or built
`candidate_refresh.v1` artifact **without replaying or mutating refresh
state** — including top-level source-report path maps by family, contract, and
trust-boundary status for branch-local adapter routing, with those summary
routing semantics advertised through the public capability catalog. Timeline
activity-precondition source summaries derive status, blocked/review counts,
and type maps from precondition rows when row evidence is present, so stale
top-level aggregate fields cannot hide branch-local replay pressure.
Timeline lifecycle-state source summaries likewise derive review,
duplicate-identity, invalid-input, action, transition-category, and routing
pressure from lifecycle rows when row evidence is present.

## Repair- and strategy-generated candidate-source metadata

Repair- and strategy-generated candidate-source metadata also preserves:

- supplied candidate-rejection, provider-counteroffer, freshness, refresh-budget, schema-validation, operational-readiness, quality-gate, model-acceptance, and validation-safety-case source-report input paths;
- branch-generated `candidate_refresh.mission_state` source-report bundles, plus normalized nested result-artifact provenance paths for branch-local handoff routing;
- with request-derived paths separately listed in `candidate_source.candidate_refresh_request_source_report_input_paths`.

## V3 strategy-derived branch-local refresh requests

V3 strategy derivation can create branch-local refresh requests from mission-state rows, carrying review evidence without selecting, importing, accepting, certifying, approving, or reserving the underlying item:

- **`candidate_rejection_report.v1` rows** that are rejected, reviewable, and require `review_candidate_rejection` — carrying candidate ID, rejection reasons, trust boundary, and source path as branch event evidence, without selecting or importing the rejected candidate.
- **`provider_counteroffer_report.v1` rows** that are reviewable and require `review_provider_counteroffer` — carrying counteroffer ID, timing, cost, start/end/duration timing deltas, lock-deadline, provider/station identity, trust boundary, and source path, without accepting the offer or reserving provider time.
- **`schema_validation_report.v1` error or warning rows** — carrying validation status/mode, validated contract, issue path/message, remediation, trust boundary, and source path, without changing candidate selection.
- **`operational_readiness_report.v1` non-importable summaries or non-passed gate rows** — carrying readiness level, import classification, gate ID/status/classification, evidence, trust boundary, and source path, without approving operator actions or writing to Cadence.
- **`quality_gate_report.v1` non-passed rows** — carrying gate ID/status/classification, row-derived readiness/count context, resource-availability reason IDs/counts when present, trust boundary, and source path, without approving operator actions or writing to Cadence.
- **`model_acceptance_report.v1` rows** that require review or are blocked/unknown — carrying intended use, model ID, validation level, acceptance status, report-level status counts, model ID routing maps, trust boundary, and source path, without certifying models or approving imports.

## Branch-local replay from review/import containers

- Operational readiness provenance also replays from branch-local `operator_review_package.v1` and `cadence_import_manifest.v1` containers, so a branch can preserve readiness routing context even when the original readiness report was only available as review/import rows.
- Schema-validation provenance follows the same branch-local replay path for `schema_validation_report.v1` rows preserved in review/import containers.
- Provider counteroffer summaries also replay from branch-local operator-review packages and Cadence import manifests, without accepting counteroffers.

## Validation and integrity

- Candidate-diff and candidate-rejection report scalar counts export and validate as non-negative integers.
- Emits the same `resource_filter_report.v1` model-limit/source-quality/trust-boundary count shape even when no resource summaries are supplied.
- Preserves declared operational-feedback trust boundaries on feedback-synthesized resource summaries and downstream resource-suppression review/import rows.
- Preserves invalid explicit or feedback-mutated resource summaries as nested `invalid_resource_summary_input` review/import evidence, with `review_status` constrained to `operator_review_required`, **without filtering refreshed candidates from malformed resource state**.
- Validates the emitted artifact through `mix orbital_dynamics.schema.lint`.

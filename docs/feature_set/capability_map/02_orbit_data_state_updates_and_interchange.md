# 2. Orbit Data, State Updates, and Interchange

## Status: **implemented**

### Study manifests and accepted planning state

- JSON study manifests can describe explicit Cartesian initial states, generated
  circular LEO scenarios, spacecraft metadata, and mission plans.
- `accepted_planning_state.v1` defines an executable input contract for accepted
  spacecraft state estimates with source, quality, and trust-boundary provenance
  metadata.
  - It requires a direct `trust_boundary` or `provenance.trust_boundary` on
    standalone and nested state-estimate rows.
- `OrbitalDynamics.OrbitData` imports/exports simple JSON/map Cartesian
  state-estimate batches into that accepted planning-state contract.
- Candidate-refresh manifests can use `candidate_refresh.orbit_data` directly and
  normalize it through the same accepted planning-state contract before
  propagation.
- Simple JSON orbit-data imports add deterministic adapter provenance
  identifying the input format and state-estimate count, and inherit that import
  trust boundary onto state-estimate rows that do not declare their own
  provenance.
- The opt-in `OrbitalDynamics.import_orbit_data_from_file/3` boundary requires a
  caller-declared lowercase SHA-256 identity, verifies exact file bytes before
  JSON decoding, consumes those returned bytes without reopening the path, and
  preserves deterministic verification evidence in accepted-state provenance.
  Existing map/binary import paths remain unchanged and do not require an
  identity.
- The current CandidateRefresh source candidate classifies accepted-state
  covariance and content-identity evidence with
  `accepted_state_evidence_authority.v1` before atom/string key normalization can
  collapse aliases. The summary is carried in CandidateRefresh accepted-state
  reference and provenance as metadata-only review evidence: covariance remains
  `metadata_only_not_consumed`, content identity remains
  `byte_identity_not_authenticated`, and decision authority remains
  `no_decision_authority`. Generated artifact/schema convergence remains
  deferred to final convergence.

### CCSDS OPM KVN import/export

`OrbitalDynamics.OrbitData` also imports and exports a narrow single-object CCSDS
OPM KVN subset for Earth-centered `EME2000`/`J2000`/`ICRF` Cartesian state
handoff. Specifically, it:

- Preserves OPM header/object/reference-frame metadata including CCSDS version,
  creation date, and originator.
- Round-trips `MASS`, drag-area/coefficient, and solar-radiation-pressure
  area/coefficient metadata as metadata-only evidence.
- Imports and exports complete OPM covariance matrix terms as
  `covariance_matrix_6x6` metadata-only evidence only when the CCSDS lower
  triangular component set is complete, finite, symmetric when expanded to 6x6,
  uses the closed exact canonical kilometer/kilometer-per-second covariance unit
  contract, binds to the accepted state frame with no conversion, binds to the
  single OPM state epoch, and passes the deterministic normalized
  principal-minor support check. Partial covariance field declarations are
  rejected.
- Preserves multiple OPM `MAN_*` maneuver metadata blocks as metadata-only
  `maneuver_execution_delta` evidence, without maneuver propagation.
- Exports maneuver-execution deltas with epoch and delta-v evidence back to
  repeated OPM `MAN_*` blocks for metadata-only round trips.

**Maneuver-delta trust boundaries** — standalone and nested maneuver-execution
deltas require a direct `trust_boundary` or `provenance.trust_boundary`, and
orbit-data adapters inherit the accepted planning-state import trust boundary
onto metadata-derived maneuver deltas.

### CCSDS OEM KVN import/export

- Imports a deliberately narrow single-object CCSDS OEM KVN Cartesian ephemeris
  by selecting one sample without interpolation, preserving CCSDS version,
  creation-date, and originator header metadata, and recording the
  sample-selection policy. This remains the default compatibility path.
- Opt-in `interpolate: true` import accepts one multi-sample Earth-centered
  `EME2000`/`J2000`/`ICRF` segment at an explicit scale-bearing
  `strategy_epoch` and required `source_revision`. It also requires a valid,
  timezone-bearing ISO-8601 accepted time, supplied by the `accepted_at` option
  or the OEM `CREATION_DATE`; the strategy epoch is never substituted as the
  accepted time. It selects an exact source sample at an exact epoch; otherwise
  it uses cubic Hermite position/velocity interpolation between the adjacent
  source samples.
- The opt-in path requires declared `START_TIME`/`STOP_TIME` coverage, honors a
  paired `USEABLE_START_TIME`/`USEABLE_STOP_TIME` interval when present, accepts
  an optional positive `max_bracket_s`, and rejects extrapolation, nonmonotonic
  or duplicate epochs, unsupported/mixed frame-time-object shapes, and
  out-of-coverage requests.
- Accepted-state provenance preserves the full source bracket, requested epoch,
  method/version, declared/effective coverage, object/frame/time metadata,
  caller source revision, exact-source-byte SHA-256 identity, deterministic
  interpolation evidence identity, assumptions, and known limits. SHA-256 is
  byte identity only, not source-authority authentication. OEM covariance is
  attached only when a single complete covariance block has the complete CCSDS
  lower-triangular component set, accepted-state frame binding without
  conversion, exact selected-sample covariance epoch text under the admitted
  time system, closed exact canonical covariance units, and the deterministic
  normalized principal-minor support check. It remains metadata only and is never
  propagated or interpolated.
- Exports a single accepted state as single-sample OEM KVN with explicit
  no-interpolation metadata.

### Validation and integrity (OPM/OEM)

- Rejects non-Earth centers.
- Rejects duplicate single-value OPM/OEM KVN fields instead of silently
  overwriting them.
- Rejects declared covariance field sets that are partial, duplicate, mixed-unit,
  unsupported-unit, frame-mismatched, coepoch-mismatched, nonfinite, or outside
  the deterministic covariance numerical support check.
- OPM/OEM covariance export is fail-closed: schema-valid ad hoc quality matrices
  are emitted only after the same local complete-matrix, frame/epoch, exact-unit,
  and numerical support checks pass; partial covariance metadata or mismatching
  covariance caller overrides return typed errors.
- OEM strategy-epoch interpolation is explicit and offline; it performs no
  provider fetch, frame transform, time conversion, or planner-default change.
- Declares supported formats plus known unsupported interchange products through
  `OrbitData.capabilities/0`.

### Public facades

The following facades expose the wrapper-aware import and accepted-state export
boundary:

- `OrbitalDynamics.import_orbit_data/2`
- `OrbitalDynamics.import_orbit_data_from_file/3`
- `OrbitalDynamics.import_ccsds_opm/2`
- `OrbitalDynamics.import_ccsds_oem/2`
- `OrbitalDynamics.export_orbit_data_json/1`
- `OrbitalDynamics.export_ccsds_opm/2`
- `OrbitalDynamics.export_ccsds_oem/2`

### Preflight adapters and provenance

Simple JSON, OPM, OEM, and TLE metadata preflight adapters stamp provenance with
the input format, import adapter, external orbit-data trust boundary, and
explicit no-network-access marker.

**TLE preflight** — `OrbitData.inspect_tle/2`:

- Parses TLE metadata including mean-motion derivatives and BSTAR drag metadata.
- Derives mean-element period, altitude, and coarse altitude-regime metadata as
  preflight estimates.
- Validates line checksums and catalog-number consistency.
- Rejects multi-object TLE drops as ambiguous input.
- Returns a metadata-only preflight record that explicitly marks the input as
  not compatible with `accepted_planning_state.v1` until a separate SGP4
  propagation regime exists.

**CCSDS OMM preflight** — `OrbitData.inspect_ccsds_omm/2`:

- Parses narrow CCSDS OMM KVN mean-element metadata.
- Validates duplicate single-value fields.
- Derives the same mean-element period/altitude/regime triage from declared mean
  motion and eccentricity.
- Preserves object/catalog/element-theory metadata.
- Rejects OMM wrappers as accepted planning-state imports until a separate
  propagation regime exists.

### Schema typing and validation registry

- The executable adapter validation is the source of truth for OPM/OEM
  covariance binding and numerical support checks. The generated JSON Schema
  remains an extensible compatibility schema for accepted-state artifacts and is
  not broadened by this slice.
- `maneuver_execution_delta.v1` types OPM `MAN_*` source, maneuver status,
  duration, delta-mass, reference-frame, and no-propagation metadata fields for
  compatibility tooling.
- Validation-registry records now declare evidence, tolerances, and known limits
  for the simple JSON, OPM, OEM, and TLE metadata orbit-data adapters.

## Status: **partial**

- The project can consume its own JSON manifests and artifacts, validate accepted
  planning-state snapshots, and use them to refresh candidate opportunities.
- It now has:
  - A simple state-estimate adapter.
  - A first OPM KVN adapter with header/object metadata, spacecraft-mass and
    physical-property metadata, complete bound covariance-matrix metadata, and
    multiple maneuver metadata-block import/export preservation.
    It exports preserved creation-date and originator metadata when explicit
    export overrides are not supplied.
  - An OEM KVN adapter with compatibility-preserving single-sample selection and
    opt-in bounded single-object strategy-epoch interpolation in the supported
    Earth inertial J2000/time-scale envelope.
  - TLE and CCSDS OMM metadata preflight boundaries that deliberately do not
    generate state vectors, derive mean-element altitude/regime triage, and keep
    SGP4/mean-element propagation separated from Cartesian state import.
- **TLE preflight** rejects ambiguous multi-object drops.
- **OPM/OEM imports** now reject duplicate single-value KVN fields.
- The project does **not** yet cover broader spacecraft metadata, multi-object or
  multi-segment OEM interpolation, covariance interpolation/propagation, external
  covariance truth validation, signature/source-authority authentication,
  Cadence authorization, executable SGP4/OMM propagation, frame/time conversion,
  or extrapolation.

## Status: **near-term**

- Broaden OPM/OEM adapters only as needed.
- Add executable SGP4 or OMM propagation only behind consciously separate
  mean-element regimes.
- Keep import/export contract tests around each interchange boundary.

## Status: **later**

- Support TLE/SGP4 as a deliberately separate propagation regime.
- Broader CCSDS OMM/OEM/OPM orbit-data coverage.
- CDM for conjunction-screening inputs.
- TDM or similar tracking/measurement products as OD inputs.
- Catalog/source provenance.
- Import/export contract tests.

## Status: **out of scope**

Owning operational orbit determination. OrbitalDynamics should consume accepted
state estimates from Cadence, OD tools, or operator-provided artifacts, then
record their source and quality.

## Product boundary

The important product boundary is:

```text
external OD/catalog/tracking source -> accepted planning state -> refreshed candidates
```

OrbitalDynamics may validate, normalize, propagate, and compare planning states,
but it should not pretend to be the authoritative OD system until that is a
deliberate project.

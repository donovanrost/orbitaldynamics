# 5. Event Detection

## Implemented

Status: **implemented**.

### Detector coverage

Sample-based detection is available for the following, as standalone APIs and as first-class study/manifest outputs:

- Ground-station access windows.
- Target visibility.
- Cylindrical central-body eclipse intervals.
- Geocentric latitude/longitude crossing events, in inertial or constant-rotation body-fixed frames.

All retain linear boundary interpolation as the compatibility default, plus
assumptions and sample-cadence timing tolerance metadata. Ground-station access
also supports an explicit, opt-in bracketed root-refinement path described
below.

### Body-fixed ground-track rotation

Body-fixed ground-track requests can declare a configured constant rotation rate, epoch, and angle offset:

- In detector opts and study manifests, or
- By passing a validated Earth-rotation provider through direct study requests and manifest JSON.

Result artifacts preserve:

- Rotation provider IDs.
- Provider models.
- Rates.
- Provider interpolation labels.
- Before/after rotation angles.

### Capability metadata and model limits

- Detector modules declare capability metadata with model labels and known limits.
- Persisted event rows expose those known limits as schema-visible `model_limits`.

### Observation-candidate lighting

V1 campaign and candidate-refresh observation candidates tag, from same-scenario sampled eclipse overlap:

- Lighting condition.
- Lighting detail bands.
- Eclipse-overlap fraction.
- Confidence.

Those lighting vocabularies are constrained by executable candidate-activity JSON Schema enums.

### Boundary-refinement helpers

The following expose bounded linear boundary-refinement helpers:

- `EventDetectors.AccessWindows.refine_aos_los_boundary/4`
- `EventDetectors.TargetVisibility.refine_visibility_boundary/4`
- `EventDetectors.Eclipses.refine_eclipse_boundary/3`
- `EventDetectors.GroundTrackCrossings.refine_crossing_boundary/3`
- Corresponding `OrbitalDynamics` public helpers.

Access-window detection and `OrbitalDynamics.refine_access_boundary/4` also
accept `boundary_refinement: :bracketed_bisection`. Omitting the option, or
passing `:linear_sample_crossing`, preserves the existing linear result and
metadata.

These share local bracket timing metadata on refined AOS/LOS, visibility, eclipse, and ground-track boundary assumptions and interpolated detected-window boundary details:

- `event_time_bracket_s`
- `before_epoch_s`
- `after_epoch_s`
- Bracket-local `event_time_tolerance_s`

### Opt-in access AOS/LOS root refinement

The access detector's opt-in path evaluates elevation margin on a cubic-Hermite
state interpolant constructed from the position and velocity at the two
bracketing samples. Deterministic bisection then retains the sign-changing half
bracket until the midpoint time-error bound is no greater than
`root_tolerance_s` (default `1.0e-3` seconds), subject to
`root_max_iterations` (default `64`, accepted range `1..100`).

The helper and detected-window boundary details record:

- The original sample bracket and final root bracket.
- The requested tolerance and actual midpoint time-error bound.
- Root solver, root function, interpolation fraction, iteration count, and
  function-evaluation count.
- Final bracket epochs and elevation margins.
- `validation_level: :analysis`, the interpolated-state root scope, and explicit
  model-limit labels.

The detector rejects incompatible endpoint frames or time scales,
non-increasing endpoint epochs, invalid solver bounds, unbracketed inputs, and
iteration exhaustion with deterministic error terms. Detected events mark
root-refined boundaries separately from sample-clipped boundaries. If either
event edge is clipped to the trajectory extent, the event-wide timing tolerance
remains conservatively bounded by sample cadence even though the refined edge
has a tighter local bound.

This is a numerical root of simplified access geometry along an interpolated
sample path. It is not dense propagator output, does not resolve multiple
crossings hidden inside one sample interval, and adds no terrain, refraction,
authoritative Earth-orientation, external-validation, or flight-fidelity claim.

### Refinement evidence and lineage

- Access, target-visibility, and eclipse events now preserve boundary-refinement details on detected windows.
- Candidate-refresh source windows carry the same interpolation/refinement evidence through schema-visible source-window metadata, with executable validation for nested source-window identity, source-window type labels, interpolation fractions, sample indices, and eclipse sun-vector shape.
- Candidate-refresh source-window lineage rows now carry compact nested source-window evidence and executable cross-checks against candidate activity identity, source-window IDs, window types, and scenario IDs.

## Partial

Status: **partial**.

- **Boundary refinement** — AOS/LOS boundaries can optionally be root-refined on
  a cubic-Hermite interpolated sample path. The default AOS/LOS path, target
  visibility, cylindrical eclipse, and sampled latitude/longitude ground-track
  boundaries remain linearly refined; no detector has dense-output propagation
  or externally validated physical event-time guarantees.
- **Lighting tags** — now distinguish overlap-fraction bands, but are still based on sampled cylindrical eclipse intervals, not penumbra or sensor illumination geometry.
- **Latitude/longitude crossings** — are geocentric; body-fixed mode uses declared constant rotation assumptions or provider-supplied rotation angles rather than a built-in authoritative Earth orientation data set.
- **Elevation masks** — are scalar minimum elevations; terrain, refraction, and refined physical illumination categories are not modeled.

## Near-term

Status: **near-term**.

- Refined lighting condition tags.
- Earth-orientation provider adapters beyond the internal constant-rate provider.
- Dense-output or propagator-coupled event evaluation for physical root timing,
  followed by external reference comparison before any tighter validation
  level is claimed.

## Later

Status: **later**.

- Terrain/horizon masks.
- Apsides.
- Node crossings.
- Conjunction and collision screening.
- Sensor-specific visibility.
- Event detector composition.

## Out of scope

Status: **out of scope**.

- Operational conjunction assessment authority without validated external data and workflow ownership.

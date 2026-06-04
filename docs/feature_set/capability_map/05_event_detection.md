# 5. Event Detection

## Implemented

Status: **implemented**.

### Detector coverage

Sample-based detection is available for the following, as standalone APIs and as first-class study/manifest outputs:

- Ground-station access windows.
- Target visibility.
- Cylindrical central-body eclipse intervals.
- Geocentric latitude/longitude crossing events, in inertial or constant-rotation body-fixed frames.

All of these use linear boundary interpolation, plus assumptions and sample-cadence timing tolerance metadata.

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

The following expose bounded linear boundary-refinement helpers, without claiming root-solved event timing:

- `EventDetectors.AccessWindows.refine_aos_los_boundary/4`
- `EventDetectors.TargetVisibility.refine_visibility_boundary/4`
- `EventDetectors.Eclipses.refine_eclipse_boundary/3`
- `EventDetectors.GroundTrackCrossings.refine_crossing_boundary/3`
- Corresponding `OrbitalDynamics` public helpers.

These share local bracket timing metadata on refined AOS/LOS, visibility, eclipse, and ground-track boundary assumptions and interpolated detected-window boundary details:

- `event_time_bracket_s`
- `before_epoch_s`
- `after_epoch_s`
- Bracket-local `event_time_tolerance_s`

### Refinement evidence and lineage

- Access, target-visibility, and eclipse events now preserve boundary-refinement details on detected windows.
- Candidate-refresh source windows carry the same interpolation/refinement evidence through schema-visible source-window metadata, with executable validation for nested source-window identity, source-window type labels, interpolation fractions, sample indices, and eclipse sun-vector shape.
- Candidate-refresh source-window lineage rows now carry compact nested source-window evidence and executable cross-checks against candidate activity identity, source-window IDs, window types, and scenario IDs.

## Partial

Status: **partial**.

- **Boundary refinement** — AOS/LOS, visibility, cylindrical eclipse, and sampled latitude/longitude ground-track boundaries can be linearly refined from bracketed sample pairs, but are not root-solved.
- **Lighting tags** — now distinguish overlap-fraction bands, but are still based on sampled cylindrical eclipse intervals, not penumbra or sensor illumination geometry.
- **Latitude/longitude crossings** — are geocentric; body-fixed mode uses declared constant rotation assumptions or provider-supplied rotation angles rather than a built-in authoritative Earth orientation data set.
- **Elevation masks** — are scalar minimum elevations; terrain, refraction, and refined physical illumination categories are not modeled.

## Near-term

Status: **near-term**.

- Refined lighting condition tags.
- Earth-orientation provider adapters beyond the internal constant-rate provider.
- Tighter timing policies when adaptive/root-finding detectors exist.

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

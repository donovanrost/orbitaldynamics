# 1. Core Astrodynamics Foundations

- `implemented`: `StateVector` with kilometers and kilometers per second;
  `Epoch` seconds since J2000 with `:tdb`, `:tai`, and `:utc` labels;
  `Frame.earth_inertial_j2000/0`; `CentralBody.earth/0`; explicit
  central-body radius, `mu_km3_s2`, and J2 metadata;
  `OrbitalDynamics.OrbitElements` converts Cartesian states into two-body
  osculating classical elements and reconstructs Cartesian `StateVector`
  values from classical elements when callers provide explicit epoch/frame
  context, with explicit singular-angle fields, two-body assumption metadata,
  frame-center checks, and capability labels;
  result-artifact trajectory summaries expose propagation capability labels
  (`propagation_backend`, `force_model`, `numerical_method`,
  `validation_level`, and `model_limits`) directly on each row, and event rows
  for access, eclipse, target visibility, and ground-track outputs expose
  detector capability labels (`event_detector`, `event_model`,
  `validation_level`, timing policy, interpolation/refinement labels, and
  `model_limits`) directly on each numerical product row;
  `OrbitalDynamics.Units` exposes an executable suffix-based units policy for
  public structs, manifests, and artifacts; `OrbitalDynamics.Frame` exposes
  explicit frame compatibility helpers and scenarios reject initial states whose
  frame center does not match the central body;
  `OrbitalDynamics.FrameTransform` provides an opt-in Earth-only J2000 inertial
  to provider-defined Earth-fixed state transform in both directions for `:tdb`
  epochs. It consumes one explicit immutable offline Earth-rotation provider
  policy, applies the rotating-frame velocity transport term, rejects unsupported
  frames/body/time scale/provider coverage, and returns provider
  source/revision/coverage plus realized round-trip tolerance evidence. The
  policy carries an internal SHA-256 same-runtime content-binding value over its
  provider module, options, capability, and source revision before any fetch; it
  is not an externally stable serialization or cross-runtime identifier.
  Per-call input and provider-product admission uses inclusive arithmetic-safety
  limits of `1.0e9 km` per position component, `2.0e4 km/s` per velocity component,
  `1.0e12 s` absolute TDB seconds since J2000, `1.0e12 rad` absolute provider
  rotation angle, and `2.0 rad/s` absolute provider rotation rate. The rate
  ceiling explicitly admits the retained `pi / 2 rad/s` quarter-rotation fixture.
  Realized round-trip admission uses the greater of the `1.0e-9 km` position and
  `1.0e-12 km/s` velocity absolute floors or `1.0e-12` times the corresponding
  realized arithmetic scale; the velocity scale includes angular-rate transport.
  The legacy `round_trip_tolerances.position_km` and `velocity_km_s` capability
  keys remain aliases for those absolute floors.
  The input box is deliberately not claimed to be closed under transformation:
  arbitrary returned states can fall outside the per-call input limits, while the
  retained forward fixed-frame state remains admissible for its inverse call.
  Supported-Earth metadata validates the presence and constructor-compatible
  type/sign semantics of `name`, `mu_km3_s2`, `equatorial_radius_km`, and `j2`;
  `nil` remains valid for the constructor-optional radius and J2 fields. Malformed
  tagged state frames, target frames, and central bodies are rejected with typed
  errors before compatibility checks or provider fetch. Error precedence remains
  numeric/state shape, central body, epoch, source frame, then target frame. These
  limits prevent non-finite or oversized transform arithmetic; they are not
  physical-validity, Earth-orientation-accuracy, or operational envelopes.
- `partial`: units and validation are enforced in constructors but not through a
  full units system; only one Earth z-axis frame pair is transformed; time scales
  remain labels rather than conversion machinery.
- `near-term`: broaden accuracy labels to any remaining numerical products that
  do not yet expose capability metadata.
- `later`: general frame transforms, authoritative Earth orientation models,
  time-system conversions, covariance/state uncertainty primitives, and broader
  central-body catalogs.
- `out of scope`: flight-certified navigation, operational orbit determination,
  and authoritative Earth orientation distribution.

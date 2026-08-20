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
  source/revision/coverage plus realized round-trip tolerance evidence.
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

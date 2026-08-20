# 4. Environment and Ephemeris Providers

## Status: **implemented**

### Environment models and assumptions

- Earth central-body constants.
- A simple fixed inertial solar direction for eclipse detection.
- An Earth-fixed geometry approximation in access calculations and body-fixed ground-track crossings.
- `OrbitalDynamics.Environment` capability records for fixed-Sun and constant-Earth-rotation assumptions, archived under result artifact `environment_models`.

### Provider capability contract

- `Environment.Provider` defines a provider capability contract with source coverage, interpolation, supported bodies, network access, and time-span coverage validation.
- Internal fixed-Sun and constant-Earth-rotation provider adapters expose the current simplified assumptions through that contract.
- The internal `ExponentialAtmosphereProvider` exposes a deterministic reference atmosphere-density product. The public atmospheric-drag evaluator and opt-in scalar `TwoBodyDrag` and `J2Drag` propagators consume that density with spacecraft ballistic properties while preserving provider identity and model provenance. `J2Drag` additionally captures source, caller/built-in revision, coverage, interpolation, and offline policy once across its full requested horizon. JSON study manifests can select it only for `TwoBodyDrag` as `exponential_reference`; `J2Drag` and custom providers remain programmatic-only.

### Schema contracts and validation

- `environment_model_capability.v1` and `environment_provider_capability.v1` rows are executable/exported schema contracts with typed model, source, supported-body, known-limit, and provider-output arrays.
- These are enforced by:
  - executable validation;
  - capability-exact `known_limits` checks;
  - conditional exact exported JSON Schema constraints for built-in environment model/provider IDs.
- **Network-access trust boundary** — model or provider capability rows that set `network_access: true` must declare a direct or provenance-supplied trust boundary before runtime or schema validation accepts them.

### Top-level facades

These facades expose the assumption and provider-capability boundary for application callers:

- `OrbitalDynamics.environment_models/1`
- `OrbitalDynamics.fixed_sun_direction/2`
- `OrbitalDynamics.constant_earth_rotation/1`
- `OrbitalDynamics.validate_environment_model_capability/1`
- `OrbitalDynamics.environment_model_capabilities/0`
- `OrbitalDynamics.environment_provider_capabilities/0`
- `OrbitalDynamics.validate_environment_provider_capability/1`
- `OrbitalDynamics.environment_provider_covers_time_span?/2`

Additional request-fit facades:

- `OrbitalDynamics.environment_provider_supports_request?/2` additionally checks requested time span, supported body, and provider output/product before a caller selects an environment adapter.
- `OrbitalDynamics.environment_provider_capabilities_for_request/1` returns the matching provider capability records directly, including product-level `earth_rotation` requests as well as field-level Earth-rotation outputs.

### Tabular Earth-orientation provider

- A network-free `TabularEarthOrientationProvider` can interpolate declared Earth-rotation angle samples for body-fixed ground-track analysis through the same provider contract.
- Ground-track requests can pass provider configuration as `{ProviderModule, opts}` or manifest JSON `earth_rotation_provider` specs, while preserving provider ID, model, angle, rate, interpolation metadata, and the configured sample-table coverage on event rows and result artifacts.
- The opt-in `FrameTransform` foundation can capture the same configured
  offline provider as an explicit policy with caller-declared source revision,
  then use its angle, rate, and finite coverage for Earth J2000
  inertial/provider-defined Earth-fixed state transforms. This does not make the
  declared samples authoritative Earth-orientation data.
- Configured tabular provider capabilities derive finite coverage and sample-count parameters from declared samples.
- The public tabular adapter preserves its legacy compatibility rule by sorting
  unordered unique samples before deriving coverage or interpolating; duplicate
  epochs still fail. The source-bound campaign loader applies its own stricter
  source-order and uniform-gap checks before delegating to this adapter.
- Public configured-provider request-fit helpers can reject out-of-table use before an adapter is selected.
- Study-runner ground-track validation now uses that configured request-fit check against the full scenario horizon, so unsupported products or short declared sample tables fail as option validation instead of late event-detection errors.
- The opt-in `OrbitalDynamics.fetch_tabular_earth_orientation_from_file/3`
  boundary accepts a JSON sample table only after the reusable exact-byte
  verifier matches an explicit lowercase SHA-256 identity. Returned provider
  products preserve verification provenance, a declared or digest-derived
  stable table ID, ordered assumptions, and known limits. Inline `samples`
  configuration remains unchanged and does not require a digest.

### Source-bound campaign environment

- `CampaignEnvironmentProvider` is an opt-in, network-free combined provider
  for a finite campaign horizon. It supplies a time-varying geocentric Sun
  direction and Earth rotation/orientation from one exact-byte-verified table;
  the fixed-Sun and constant-Earth-rotation defaults are unchanged when the
  provider is absent.
- The checked-in demonstration table covers 2026-01-01T00:00:00Z through
  2026-01-04T00:00:00Z at one-day intervals. Its Sun positions are from the
  JPL Horizons `DE441` geocentric-Sun vector response, and its polar motion and
  UT1-UTC values are final Bulletin B columns from the IERS/USNO
  `finals2000A.all` product. The table records the exact source URLs, product
  and source revisions, query and epoch conventions, derivations, retrieval
  timestamp, raw IERS source rows, the four exact Horizons `$$SOE` rows, a
  reproducible SHA-256 of those extracted rows, retrieval-response SHA-256
  metadata, and its own SHA-256 identity. Loading parses the checked-in
  Horizons rows and requires every table epoch/vector to match them exactly.
- The only supported interpolation is deterministic component-wise linear
  interpolation inside the declared adjacent sample bracket. Sun Cartesian
  positions are interpolated before normalization; Earth rotation angle uses
  the IERS Earth Rotation Angle expression evaluated at each sample's UT1 and
  then linearly interpolated without discarding whole turns. ERA properly
  relates CIRS to TIRS, but this bounded path does not implement the required
  celestial-intermediate/precession-nutation transform. It therefore labels
  its direct ERA rotation of repository `eci_j2000` as
  `earth_fixed_era_from_eci_j2000_approximation`, does not claim TIRS, and does
  not apply polar motion. Polar motion and UT1-UTC are still archived and
  interpolated component-wise. The separate JPL ICRF-to-repository
  `eci_j2000` axis mapping remains an explicitly documented approximation.
- Loading rejects an unverified table, an unexpected provider/table/source
  revision, source digest mismatch, wrong body/frame/time scale, duplicate or
  nonmonotonic epochs, nonuniform gaps, inconsistent coverage, and unsupported
  interpolation. JSON objects with duplicate keys are rejected at every
  nesting level before semantic decode. Loaded datasets are sealed by one
  hardcoded canonical digest of every semantic dataset field and normalized
  file-verification evidence; altered caller-constructed dataset structs fail
  closed. Improper lists and malformed containers also return structured
  dataset errors on every public reuse path rather than escaping validation.
  Requests must fit wholly within the finite table coverage.
- `StudyRunner` accepts only the built-in provider through the programmatic
  `campaign_environment: {CampaignEnvironmentProvider, options}` run option;
  the selectable file configuration must be the exact checked-in option set,
  while the reused `Dataset` form is accepted only when its sealed semantic and
  exact-file identities match the checked-in bytes. This is a built-in-module
  and content-identity boundary, not caller authentication or a signature over
  the upstream products. Arbitrary caller modules fail before event generation. The
  generic ground-track provider extension remains available, but its configured
  capability is bound to its module capability and every returned identity or
  provenance field is checked against that configured capability. A generic
  module cannot claim the reserved campaign ID, limits, digests, table identity,
  or `campaign_environment` provenance; only the exact built-in provider with a
  validated checked-in configuration may emit that evidence. Consumed
  eclipse and body-fixed ground-track results, result artifact assumptions,
  checkpoint identity, and exported environment-model rows archive the exact
  provider, provider revision, dataset revision, semantic dataset SHA-256,
  table ID/content SHA-256, honest approximation frame, finite coverage,
  interpolation, and source-product provenance. Campaign ground-track result
  limits describe ERA/UT1 consumption and the omitted frame transforms;
  legacy runs retain the constant-rotation/no-EOP limits unchanged. Mixed
  campaign runs also archive `environment.earth_rotation.constant_rate` when
  access-window or target-visibility work consumes `AccessGeometry`; a
  campaign-only body-fixed ground-track run archives only the ERA approximation
  rotation model.
- This is a source-binding and request-fit proof. It is not the Domain 18
  external numerical acceptance case: the checked-in derived table is small,
  no independent high-fidelity oracle comparison or error budget is claimed,
  and no general-purpose SPICE/EOP ingest or update service is provided.

## Status: **partial**

There is now a provider behaviour and internal assumption-backed providers, including:

- a reference atmosphere-density provider consumed by a standalone drag acceleration evaluator and opt-in scalar two-body-drag and J2-drag propagation;
- a declared-sample Earth-orientation table adapter.

But the following are still missing:

- no general-purpose Sun/Moon/planet ephemeris data provider beyond the bounded
  checked-in campaign table;
- no live external-provider data source adapter;
- no Nx or EXLA propagator consumes atmosphere density as drag; the only J2
  consumer is the bounded opt-in scalar `J2Drag` path.

## Status: **near-term**

- Add general external ephemeris or Earth-orientation provider adapters only
  behind the provider contract, with explicit source coverage, request-fit
  validation, interpolation method, supported bodies, declared outputs, and
  network policy.

## Status: **later**

- SPICE, Orekit, GMAT, Tudat, or service adapters.
- Calibrated solar flux and atmosphere providers.
- Body-fixed/inertial model packages.

## Status: **out of scope**

- Bundling or maintaining a general authoritative external ephemeris archive as
  a core project obligation; the small checked-in campaign proof is deliberately
  finite and immutable.

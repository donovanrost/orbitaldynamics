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
- The internal `ExponentialAtmosphereProvider` exposes a deterministic reference atmosphere-density product. The public atmospheric-drag evaluator and opt-in scalar `TwoBodyDrag` propagator consume that density with spacecraft ballistic properties while preserving provider identity and model provenance. JSON study manifests can select it as `exponential_reference` and declare reference altitude, reference density, and scale height without network or dynamic module loading; custom providers remain programmatic-only.

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
- Configured tabular provider capabilities derive finite coverage and sample-count parameters from declared samples.
- Public configured-provider request-fit helpers can reject out-of-table use before an adapter is selected.
- Study-runner ground-track validation now uses that configured request-fit check against the full scenario horizon, so unsupported products or short declared sample tables fail as option validation instead of late event-detection errors.
- The opt-in `OrbitalDynamics.fetch_tabular_earth_orientation_from_file/3`
  boundary accepts a JSON sample table only after the reusable exact-byte
  verifier matches an explicit lowercase SHA-256 identity. Returned provider
  products preserve verification provenance, a declared or digest-derived
  stable table ID, ordered assumptions, and known limits. Inline `samples`
  configuration remains unchanged and does not require a digest.

## Status: **partial**

There is now a provider behaviour and internal assumption-backed providers, including:

- a reference atmosphere-density provider consumed by a standalone drag acceleration evaluator and opt-in scalar two-body-drag propagation;
- a declared-sample Earth-orientation table adapter.

But the following are still missing:

- no Sun/Moon/planet ephemeris data provider;
- no live external-provider data source adapter;
- no J2, Nx, or EXLA propagator consumes atmosphere density as drag.

## Status: **near-term**

- Add external ephemeris or Earth-orientation provider adapters only behind the provider contract, with explicit source coverage, request-fit validation, interpolation method, supported bodies, declared outputs, and network policy.

## Status: **later**

- SPICE, Orekit, GMAT, Tudat, or service adapters.
- Calibrated solar flux and atmosphere providers.
- Body-fixed/inertial model packages.

## Status: **out of scope**

- Bundling or maintaining authoritative external ephemeris data as a core project obligation.

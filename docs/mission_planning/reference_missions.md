# Configurable reference missions

This opt-in analysis slice explores a Reflect-like illumination service without
assuming access to Reflect Orbital spacecraft specifications. A second optical
imaging case exercises the same interfaces. The examples are synthetic experiments,
not predictions of either company's capabilities or validated operations plans.

## Run and iterate

From the repository root:

```sh
mix orbital_dynamics.mission.run --manifest studies/reference_illumination.json --output tmp/illumination.json
mix orbital_dynamics.mission.run --manifest studies/reference_imaging.json --output tmp/imaging.json
mix test test/orbital_dynamics/mission_analysis
```

Each example currently schedules one request. Change the JSON payload limits,
target, duration, or resource budget and rerun. The focused tests run in under a
second after compilation on the development machine. Reports contain sampled
geometry, every eligibility check, assumptions, windows, selected activities,
resource balances, and reasons for rejection. `jq '.activities, .requests'` gives
a compact view. Failed check counts live under `.analyses[].failed_check_counts`.

All `_s` epochs are absolute UTC seconds since J2000 in these JSON examples;
durations are seconds. Positions and target radii use kilometers. Optical area
uses square meters, irradiance W/m², and GSD meters. Resource keys include their
units; `energy_wh` is an example declared cost, not power-system simulation.

The manifest reader rejects duplicate keys, unknown fields and unknown model
names. The reference adapter accepts at most 20 assets, 100 requests, a day of
propagation, and the core permits at most 100,000 sample evaluations. Environment
coverage must include the whole propagation interval. Missing capabilities,
physical ineligibility, scheduling conflicts, and model/environment errors remain
distinct. An environment failure aborts analysis instead of becoming a physical
rejection.

## What is shared

`MissionAnalysis.run/4` accepts existing trajectories and opaque requests. It
knows about asset identities, times, opportunity grouping, values, static budgets,
and scheduling. It has no illumination, imaging, Earth, or target-specific branch.
A model implements `capabilities/0`, `prepare/3`, and `evaluate/3`; evaluations
supply named boolean checks and JSON-safe metrics. The request's subject and the
run's context belong to the model. Trusted Elixir modules implement models;
manifest strings cannot load arbitrary code.

`SphericalScene` supplies shared surface geometry from an explicitly selected
body, inertial frame, time scale, and environment provider. `Illumination` and
`Imaging` use it; a communications or non-surface model need not. Analytic tests
also exercise a different central body and an opaque model without surface targets.
`Environments.Fixed` offers explicitly configured finite-coverage constant-Sun
geometry for controlled experiments. New environments implement `at/2` and
`describe/1`; the runner performs no implicit frame or time conversion.

`ReferenceMission` is a deliberately narrower convenience adapter: Earth,
circular initial SSO estimates, J2 propagation, two named surface models and the
checked-in JPL/IERS campaign environment for January 1–4, 2026. Arbitrary missions
use the core API with their own trajectories, models, and contexts. This establishes
an extension point; it does not implement every mission type.

This lives alongside the existing observation/downlink `CampaignPlanner`.
Its standalone `format: mission_analysis.v1` report is an experimental analysis
format, not a registered artifact schema, importable `MissionPlan`, approved plan,
or executable command sequence. No existing catalog or campaign contract changes.

## Physics and assumptions

### Orbit and environment

For a circular orbit, the first-order J2 secular node rate is

```
n = sqrt(mu / a³)
node_rate = -(3/2) J2 n (R/a)² cos(inclination)
node_rate_required = 2π / solar_year_s
```

At 600 km with the example year, this gives about 97.788° inclination. The
example 18-hour ascending node is a configurable assumption, not a requirement
for all illumination missions. Sun synchronism maintains approximate local
solar time; it does not guarantee visibility, continuous service, or sunlight.
RAAN is estimated from initial Sun right ascension plus 15° × (node hour − 12).
Initializing osculating elements from this mean-rate estimate and propagating
J2 does not produce an exact long-term sun-synchronous orbit. There is no drag,
orbit determination, maintenance maneuver or repeat-ground-track design here.

See the [first-order derivation in SatelliteAnalysis](https://juliaspace.github.io/SatelliteAnalysis.jl/stable/man/orbits/sun_synchronous_orbits/).
The environment adapter preserves the existing dataset's source revisions,
verified content identity, coverage and known limits in each report. It inherits
the explicit approximation of applying Earth rotation angle directly to J2000
axes; it does not apply precession/nutation or polar motion. Targets use spherical,
geocentric coordinates. Eclipse uses a cylindrical point-Sun shadow with no penumbra.

### Illumination

For unit spacecraft-to-Sun direction `s` and spacecraft-to-target direction `t`,
the required ideal flat-mirror normal is `normalize(s + t)`. The model predicts:

```
transmitted_power = solar_irradiance × mirror_area × cos(incidence)
                    × reflectivity × atmospheric_transmission
solar_image_diameter = 2 × slant_range × tan(solar_angular_diameter / 2)
nominal_ground_irradiance = transmitted_power × sin(target_elevation)
                           / (π × (solar_image_diameter / 2)²)
```

Ranges are converted to meters in these equations. This is an ideal uniform
solar disk, small flat mirror, and local planar ground projection. The example
uses 1361 W/m² and 0.53° solar diameter; see [NASA's solar irradiance reference](https://earth.gsfc.nasa.gov/climate/projects/solar-irradiance/science)
and [NASA's thermal environment course](https://ntrs.nasa.gov/api/citations/20220013453/downloads/TFAWS-2022-Short%20Course-Environments_Vector_Shading_MERGED.pptx.pdf).
All mirror size, reflectivity, transmission, rate and pointing limits are invented
reference assumptions supplied explicitly in JSON. Transmission is constant;
clouds, altitude-dependent attenuation, focusing, finite aperture edge effects,
limb darkening, pointing error and achieved attitude are unmodeled.

Eligibility requires a visible target, target darkness, spacecraft sunlight,
nondegenerate reflection, permitted mirror incidence and sampled tracking rate,
and the requested nominal irradiance. A centered circular target must fit in the
nominal footprint's minor axis. The mirror's declared maximum dimension must be
at most 5% of the solar-image diameter to limit this approximation. The solar
cone half-angle must also be smaller than target elevation to avoid crossing the
local tangent horizon. Nominal
irradiance is not a guaranteed minimum delivered across the actual target.

### Imaging

A target-centered camera uses the same geometry and runner. Its nominal minor
footprint width is `2 × range × tan(FOV/2)`. At the field center, worst-axis nominal ground sampling
distance is that width divided by pixel count and `sin(elevation)`. The model
checks daylight, elevation, off-nadir angle, sampled boresight tracking rate,
target fit, and requested GSD. It omits optical MTF, exposure, smear, clouds,
terrain, image quality, and achieved attitude. Full FOV is limited to 10° for
this small-angle estimate, and the square FOV corner angle must stay above the
local tangent horizon. The GSD metric is a center estimate, not a fieldwide
worst-pixel bound.

## Optional attitude planning

The separate [attitude-planning path](attitude_planning.md) adds explicit initial
orientation, full pointing profiles and kinematic transition checks. The original
reference command retains its fixed-separation policy. The attitude path is not
an actuator/achieved-attitude model or a screen for transition keep-out constraints.

## Planning limits and next work

Windows span only consecutive eligible samples with bounded gaps. Isolated
samples cannot support positive-duration service. Constraints may fail between
samples; there is no root finding or continuous feasibility certification.
The optional [resolution-study path](resolution_studies.md) refines observed
transition brackets and compares fixed-lookback rates and numerical resolutions.
The original reference command keeps its sampling policy unchanged.

Tracking rates are secant estimates between pointing vectors. The first sample
without a sufficiently close predecessor fails the rate check. Neither an
initial acquisition nor the slew between two activities is verified.

The scheduler greedily orders candidates by request value and fits one continuous
activity per request on one asset. It enforces asset separation in seconds and
non-replenishing declared budgets. Separation is an assumption, not a computed
slew time. It cannot aggregate multiple mirrors, partially fulfill requests,
model simultaneous payload operations, guarantee optimality, or repair a running
plan. Predicted sample metrics belong to their samples, not an integrated delivery
estimate over the selected interval.

Before operational use, independently validate geometry and optics, refine
window boundaries, add actual attitude/power/thermal constraints, compare against
trusted ephemeris tools, and obtain real spacecraft and service requirements.
The [trade-study runner](trade_studies.md) now sweeps altitude, node time, mirror
area, tracking limits and service requirements through these interfaces. It
includes an independently checked baseline for matched-input J2 propagation and
sampled geometry. Optics, attitude and operational behavior remain unvalidated.

## Verification record

Validation for this slice: `mix test.fast` passed 5,105 tests (1,127 integration/
exhaustive tests excluded). The focused analysis tests passed all 17 cases and
the new CLI integration tests passed both cases. Both documented CLI commands
were also exercised. Independent review findings about cone/horizon validity
and malformed model preparation were resolved and regression tested.

Focused tests cover analytic reflection direction, power/footprint conservation,
inverse-square irradiance, nadir camera geometry, eclipse/daylight/throughput
rejection, provider coverage, a second body, SSO node rate, missing samples,
resource exhaustion, conflicts/separation, deterministic replay, and both complete
reference runs. These are primarily internal consistency checks. The separately documented
[Orekit baseline comparison](trade_studies.md#independently-checked-baseline) adds
scoped external numerical evidence for one trajectory and its geometry; it
does not validate service delivery or flight operations.

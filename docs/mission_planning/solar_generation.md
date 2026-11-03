# Geometry-derived solar generation

The battery model can use fixed, body-mounted solar panels instead of a supplied
charging time profile. Panel incidence uses the complete body-to-inertial
attitude at every resource midpoint, including activities, maneuvers and terminal
holds. Spacecraft shadow uses an explicitly selected cylindrical point-Sun or
spherical finite-Sun model. Both runnable studies select finite Sun. Hardware parameters and irradiance remain declared
assumptions; this is analysis support, not spacecraft validation.

## Runnable studies

```sh
MIX_ENV=test mix orbital_dynamics.mission.attitude \
  --study studies/illumination_solar.json --output-dir tmp/solar

MIX_ENV=test mix orbital_dynamics.mission.attitude \
  --study studies/solar_eclipse.json --output-dir tmp/solar_eclipse
```

The short 250-second illumination study retains the north request at +61 through
+81 seconds. It uses a synthetic 2 m² panel along body +X, panel efficiency 0.3,
bus efficiency 0.9 and fixed irradiance 1,361 W/m². Its battery starts at 35 Wh,
with 50 Wh capacity and 8 Wh reserve. These storage inputs differ from the
previous declared-power example; the two studies are not a controlled hardware
comparison. The 10-, 2- and 0.5-second resource cadences yield approximately
25.89558/25.93060/25.93048 Wh final energy, with a 0.03503 Wh spread.
The minimum-state energy range is 22.95973–22.99476 Wh. All support the declared
reserve. No contact is discovered in this short example under its search policy.
Zero-power samples can result from the panel pointing away from the Sun.

The 6,000-second study uses a separate synthetic **noon** sun-synchronous orbit to
exercise eclipse entry and exit, rather than assuming the short reference arc
contains them. It starts at 1,000 Wh, with 1,200 Wh capacity and a 100 Wh reserve.
It selects no service activities. Its path policy deliberately uses only a
permissive inertial angular envelope so that the case isolates solar-resource
behavior; it does not inherit the short study's Sun/limb/beam exclusion rules and
is not a Reflect operations reference plan. Both orbit and Sun direction use the
existing checked state/environment adapters.

| Resource cadence | Final battery Wh |
| --- | --- |
| 60 s | 1094.04499 |
| 20 s | 1094.04443 |
| 5 s | 1094.04437 |

The shared search finds outer contacts at about +1461.86035/+3599.57520 s
and total-shadow contacts at +1470.44434/+3590.98145 s. Each final bracket is
0.009765625 s wide relative to the runtime state source. No antumbra contact is
discovered in this case. The final-energy spread is about 0.00062 Wh, compared
with approximately 1.01422 Wh in the previous binary-shadow, midpoint-only
example. This compares numerical sensitivity, not a controlled physical truth.

Contact bracket endpoints and estimates partition every integration cadence.
Power still uses midpoint quadrature, including within penumbra. Root brackets
do not bound integrated-energy error, nor does cadence agreement validate the
hardware inputs. Orbit integration/output controls and power cadences remain
independent.

## Source model and inputs

Set the battery's `generation` configuration to:

```json
{
  "kind": "solar_array",
  "shadow_model": "finite_sun",
  "solar_radius_km": 695700,
  "solar_distance_km": 149597870.7,
  "event_search": {
    "max_check_step_s": 20,
    "time_tolerance_s": 0.01,
    "max_iterations": 64,
    "max_evaluations": 100000
  },
  "solar_irradiance_w_m2": 1361,
  "bus_efficiency": 0.9,
  "panels": [
    {
      "id": "array",
      "area_m2": 2,
      "efficiency": 0.3,
      "normal_body": [1, 0, 0]
    }
  ]
}
```

The model accepts 1–32 panels with unique IDs. Each normal is normalized in body
axes. The Hamilton active body-to-inertial quaternion rotates that direction into
the asset's declared inertial frame. For a panel with rotated unit normal `n` and
unit direction `s` toward the Sun:

```
incidence = max(0, dot(n, s))
panel_bus_w = irradiance_w_m2 * area_m2 * incidence
              * panel_efficiency * bus_efficiency * sunlight_factor
```

Sum the single-sided panels. Opposed panels represent separate surfaces; the back
of one panel does not implicitly produce power. The battery subtracts loads from
this bus power, then applies its own charge/discharge efficiency to the remaining
storage flow. Panel, bus and battery efficiencies each apply once at their
respective boundaries.

The finite-Sun model places a spherical Sun at the declared constant range
along the environment's body-to-Sun direction. Shared occultation geometry
computes apparent angular radii and uniform angular-disk overlap, distinguishing
sunlight, penumbra, umbra and antumbra. `sunlight_factor` is its visible fraction.
The panel normal uses the spacecraft-to-Sun center ray. Multiplying disk-area
fraction by center-ray cosine is a separable approximation, not a projected
finite-disk radiance integral, especially near a panel's 90-degree incidence edge.

For the optional `cylindrical_point_sun` model, omit solar radius, distance and
event-search fields. Its binary factor is zero for anti-sunward positions inside
the cylindrical body shadow and one otherwise; exact model tangency is sunlight.
It retains midpoint-only shadow sampling. The reported cylindrical shadow margin
is `max(dot(r,s), norm(r-dot(r,s)*s)-body_radius)` in km; for finite Sun this is a
legacy diagnostic, not a contact margin or physical uncertainty bound.

The scene explicitly supplies the spherical body, inertial frame, time scale,
Sun-direction provider and finite environment coverage. The solar model captures
body radius, frame, scale and environment/source metadata in assumptions.
Irradiance is a separate fixed input; it is not inferred from the Sun-direction
provider or automatically scaled with Sun distance.

Known finite environment-coverage edges are integration boundaries. A step
outside them is unknown, even if its midpoint alone would fall inside coverage.
A missing scene, missing finite coverage declaration, out-of-coverage source, or
explicit `null` panel/irradiance/efficiency parameter is unknown, never guessed as
zero generation. Configuration fields are strict. Invalid frames, epochs,
parameters or provider failures remain errors. Unknown propagation leaves a null
final state and an explicit uncovered suffix, as with other resource models.

## Replaceable generation providers

`Resource.Generation` separates power-source calculations from storage dynamics:

- `prepare(asset, context, configuration)` returns one opaque session and a
  JSON-safe assumptions map.
- `boundaries(session)` declares known absolute-epoch discontinuities.
- Optional `search_boundaries(session, source)` returns contact boundaries and
  evidence, unknown, or an error using a checked runtime state source.
- `evaluate(input, session)` returns `{:ok, nonnegative_bus_watts, metrics}`,
  `{:unknown, reason}` or `{:error, reason}`.

Input is the resource model's sampled state, full pointing, mode, scope, phase
and interval timing. Generation is frozen at the midpoint for that resource
interval. The prepared session is reused through candidate and final replays;
midpoint source calls are within the battery-step evaluation budget. Contact
searches have a separate explicit state/function evaluation budget and are
cached per asset, model and horizon. Their complete reports are retained in
resource assumptions; errors abort analysis and incomplete searches make that
model unknown without hiding independent model violations. The initial
zero-duration battery check does not query source power.

`Battery.prepare_with_generation/4` accepts an explicitly trusted `{Module,
configuration}` provider. A custom resource model can delegate to it for other
sources or higher-fidelity array physics. The JSON adapter chooses only built-in
`constant`, `piecewise_constant` and `solar_array` sources; it never loads a
module named by input text. Existing declared-power JSON studies retain their
behavior. Battery sessions are opaque; call `prepare` again for a changed
configuration rather than mutating a prepared session.

## Evidence, numerical sensitivity and limits

Resource samples include nested `generation_evidence`: Sun direction, panel
normals in inertial axes, incidence cosines, nominal unshadowed incident watts,
per-panel bus power, shadow state and shadow margin. Top-level metrics retain
load, generation and battery power. Cadences all gate selection, and the battery
is replayed through the entire declared horizon for every accepted candidate.

Each resource model now reports `state_comparison`, with final-state and minimum-
state ranges across all tested cadences. These are comparisons of top-level
numeric state fields under the same initial conditions. If any cadence lacks a
complete final state, comparison is incomplete; missing numeric fields are not
silently treated as zero. Classification agreement alone does not imply numerical
agreement. No automatic numeric-spread tolerance or finest-grid oracle is added.

The reference adapter also attaches `solar_generation_diagnostics`, available to
programmatic callers through `Resource.SolarDiagnostics.annotate/1`. It records
observed power ranges and shadow-change brackets from actual midpoint epochs.
The Markdown report includes those brackets and energy spreads. Full input and
power traces remain in `report.json`.

Contact discovery uses the same checked state callback as planning replay, with
an explicit maximum scan step, root tolerance and budget. It is not inferred from
stored trajectory cadence. Environment coverage gaps remain unknown, while
provider errors and budget exhaustion fail analysis. Arbitrarily narrow contacts
or grazes may remain undiscovered; zero contacts does not prove continuous
sunlight. Root bounds apply to the supplied numerical model only.

The model omits body flattening, atmosphere, terrain, reflected/albedo power,
array self-shadowing, deployment/hinges, mode-dependent inhibition, degradation,
thermal effects, maximum-power tracking and regulator dynamics. Panels remain
fixed to the body in every mode. Finite-Sun disk overlap does not provide an
operations acceptance certificate or a conservative energy bound.

## Verification scope

Analytic cases check normal/60°/90°/back-face incidence, mounting transforms,
efficiencies, opposed panels and shadow tangency/near-limb behavior. Seeded cases
compare shadow state against a separately formulated forward ray–sphere
intersection. A circular toy orbit has independently derived point-Sun eclipse
contacts at `pi ± asin(R/r)` and known illuminated duration; the full-horizon
battery test compares its energy against that analytic duration and examines
cadence differences. Other tests verify attitude-dependent candidate rejection,
terminal maneuver/hold power, environment-coverage truncation, opaque source
sessions, malformed assumptions and provider failures. These checks verify the
implementation under declared approximations, not actual solar-array or eclipse
performance.

Historical verification of the initial cylindrical-power slice: all 5,204 fast-suite tests passed (1,142
integration/exhaustive checks excluded); all 131 focused mission-analysis/mission
CLI checks passed. The unknown-input report-rendering regression and solar CLI
checks passed after the renderer refinement. The frozen numerical baseline
command still passes. Formatting and diff whitespace checks pass; independent
review found no remaining blocker. Full integration/exhaustive suites were not
rerun. The new solar tests use analytic and alternate geometric formulations;
the existing frozen Orekit baseline does not validate solar hardware or the new
power model against an independent flight/array simulator.


The finite-Sun consumer migration passed all 5,241 fast tests (1,143 excluded),
41 focused capability/schema/validation/solar-array checks, both solar CLI
integration tests, and the frozen numerical mission baseline. New cases cover
partial/total lighting, contact brackets on an analytic runtime source, source
and environment gaps, budget failure, error propagation and independent resource
violations. Independent review found no remaining blocker. Full integration and
exhaustive suites were not run; see [event migration evidence](orbital_events.md#consumer-migration-evidence).


[Independent finite-Sun checks](event_verification.md#independent-finite-sun-reference)
now compare catalog contacts, visible fractions and the actual solar-array
consumer with frozen Orekit angular geometry and independently integrated disk
areas. These are matched-model geometry and power checks; they do not validate
array hardware, the radiance approximation or integrated battery-energy error.

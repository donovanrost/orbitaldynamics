# Orbital-event catalog and shared search

`EventDetector.search/3` is the canonical standalone analysis API for the bounded
catalog below. It evaluates geometric scalar functions over a finite, explicitly
framed state source, searches for crossings and observed extrema, and refines
bracketed targets. Events are discovered from geometry; they are not predicted
from a timetable. The search controls determine where the algorithm looks and
how precisely it locates an observed target.

The catalog is a defined implementation target, not a claim to cover every
possible orbital/mission phenomenon. `EventSearch.Catalog.describe/0` exposes a
machine-readable inventory of 22 available builders and their model limits.
The grouping follows common event-finding capabilities in
[Orekit](https://test.orekit.org/site-orekit-13.1.4/apidocs/org/orekit/propagation/events/package-summary.html)
and [NASA SPICE Geometry Finder](https://naif.jpl.nasa.gov/pub/naif/toolkit_docs/C/req/gf.html).

## Coverage matrix

All rows are implemented as explicit-model standalone analysis functions. Their
validation is limited to analytic and regression cases, not operational acceptance.

| Family | Implemented scope | Important limits |
| --- | --- | --- |
| Orbital landmarks | Directed nodes/plane crossings, periapsis and apoapsis | Explicit reference plane/center; nonisolated and underresolved zeros stay unknown |
| Thresholds | Arbitrary scalar, radius, spherical altitude and plane offset | Explicit units, thresholds and value tolerances |
| Orbital coordinates | Osculating true anomaly, latitude and longitude crossings | Circular/radial anomaly undefined; geocentric coordinates; explicit z-axis rotation; meridian antipode filtered |
| Solar angles | Orbital-plane/Sun beta angle and angular-separation thresholds | Simultaneous geometry; explicit inertial axes and sources |
| Eclipses/occultations | Any, penumbra, umbra and antumbra contacts and intervals; nominal visible fraction | Spherical bodies, finite source, resolved foreground ordering; no light-time or atmosphere |
| Ground geometry | Station/target visibility, elevation extrema, day/night and twilight thresholds | Spherical points, declared elevation limit, no terrain/refraction |
| Instrument geometry | Circular target-center field of view and pointing-axis limb clearance | Explicit body-to-inertial pointing; no extended-target footprint or lens model |
| Geographic regions | Entry/exit of geocentric spherical caps | No polygon, terrain or geodetic ellipsoid model |
| Relative geometry | Range thresholds, closest approach and intersatellite visibility | Common origin/axes/scale; spherical occulting body; no covariance or collision probability |
| General extrema | Local minima/maxima of an explicit quantity | Central differences on a matching padded source; derivative-step error remains |
| Composition | Normalized signed-margin all/any/negation | Each child declares its inequality and scale; nonsmooth grazing behavior not inferred |

Specialized magnetic/radiation regions, arbitrary polygons, footprint-overlap
geometry, light-time/aberration corrections and covariance-based conjunction risk
remain extensions. An eclipse detector is not an atmosphere or thermal model.

## Runnable reference

```sh
MIX_ENV=test mix orbital_dynamics.events.demo --output-dir tmp/events
```

This writes `report.json`, `catalog.json` and a compact `README.md`. The reference
runs 21 event functions on a synthetic analytic two-body ellipse and geometric
companion sources. Its body has radius 1 km and gravitational parameter 1 km³/s²;
the orbit has semi-major axis 2 km, eccentricity 0.25 and inclination 30 degrees.
An oversized apparent Sun makes partial/total contacts easy to observe. It is a
software reference case, not a spacecraft or Reflect mission estimate. Annular
geometry has separate regression cases; an individual reference orbit need not
encounter every event type.

## State sources and preferred numerical path

Use a propagator's continuous/dense state evaluator when available, or an
explicitly controlled propagation callback. This keeps event searches independent
of output-file cadence. An analytic state evaluator is also useful for validation.

```elixir
source = OrbitalDynamics.EventSearch.Source.new!(
  fn t -> checked_state_at(t) end,
  Epoch.new!(coverage_start, :tai),
  Epoch.new!(coverage_end, :tai),
  declared_frame,
  %{"evaluation" => "caller_supplied_propagator", "integration_step_s" => step_s}
)

functions = [
  OrbitalDynamics.EventDetectors.Nodes.function("nodes", {0, 0, 1},
    value_tolerance: 1.0e-8),
  OrbitalDynamics.EventDetectors.Apsides.function("apsides",
    value_tolerance: 1.0e-8)
]

{:ok, report} = OrbitalDynamics.EventDetector.search(source, functions,
  starts_at: Epoch.new!(search_start, :tai),
  ends_at: Epoch.new!(search_end, :tai),
  max_check_step_s: 10,
  time_tolerance_s: 0.001,
  max_iterations: 64,
  max_evaluations: 100_000
)
```

The callback returns `{:ok, StateVector}`, `{:unknown, reason}` or
`{:error, reason}`. Coverage, frame and time scale are explicit; returned states
must match the requested epoch exactly. Positions/velocities must be finite.
Velocity-derived functions assume velocity is the time derivative of position in
the declared axes. No frame, origin or time-scale conversion is inferred.
Provenance is caller-declared evidence, not a certification of the evaluator.

For stored trajectories, choose interpolation explicitly:

```elixir
source = OrbitalDynamics.EventSearch.Source.from_trajectory!(trajectory,
  interpolation: :cubic_hermite)
```

This uses endpoint positions and velocities for cubic-Hermite position and its
consistent velocity derivative. It is not dense propagation. Narrow root brackets
on that interpolant do not bound the difference from the physical trajectory.
State-source methods and limits are retained in every report.

The old detector namespaces expose the common engine too:

- `AccessWindows.search/5` and `TargetVisibility.search/5`;
- `GroundTrackCrossings.search/6`;
- `Eclipses.search/7` for finite-source contacts;
- `Eclipses.search_cylindrical/4` for the existing point-Sun geometry.

All accept the same explicit source and numerical search controls. Geometry stays
in small function builders. StudyRunner, the public trajectory facades and the
executable candidate-refresh runner now use `EventSearch.Products`: one shared
search algorithm with an explicit cubic-Hermite source. Campaign candidates and
refreshed windows retain its root brackets, search controls, source provenance
and analysis-only validation label through strict event admission. Execution
policies bind the shared engine and its dependencies by executable identity.

The trajectory product policy scans at the smaller of the largest anchor gap
and 60 seconds, increased only when needed to remain within 9,999 intervals.
It uses 1 ms time tolerance (or the explicitly requested access tolerance),
64 iterations and 100,000 shared state/function evaluations. Realized controls
are recorded; a narrow root bracket does not validate the interpolated orbit or
prove that the scan discovered every event. Incomplete searches fail closed.
Elevation maxima and shadow statistics describe observed search samples, not
continuous extrema. The existing `.detect` and boundary helpers remain isolated historical reference
paths for the frozen sampled-detector/Orekit validation cases; their validation
does not transfer to the migrated products. New nodes/apsides can emit typed
point events through adapters using explicit Hermite sources.

Finite-Sun solar generation also uses the common occultation geometry. Its
contact search runs on the actual planning state callback, rather than a second
interpolated trajectory. See [solar generation](solar_generation.md).

## Search semantics

A `Function` callback returns `{:ok, value, rate_or_nil, metadata}`. The rate, when
supplied, is the derivative of that same scalar in those same axes. Values, rates,
units, tolerance and JSON-safe metadata are validated. Functions can also return
unknown or error explicitly. Constructors capture all parameters before a search.
Callbacks must be synchronous and deterministic; independent searches have
process-isolated evaluation contexts.

The engine checks a bounded grid and bisects observed sign changes. An observed
rate sign change enables a stationary-point search inside that check interval;
this can discover a grazing candidate or two crossings hidden around an observed
extremum. There can still be more extrema/crossings between checks. `scan_epoch_count`
and `maximum_observed_scan_gap_s` describe the actual grid, including floating-point
placement. A check interval is not a proof of an event-free interval.

Point records distinguish:

- `sign_change_root`, with a bracket for a scalar zero;
- `exact_sample_zero`, recording a numerical zero at an evaluated epoch;
- `stationary_contact_within_value_tolerance`, a **candidate** whose bracket
  locates a stationary point, not necessarily a zero of the original scalar.

`timing_target`, residual value and `event_class` keep that distinction explicit.
`midpoint_time_bound_s` is relative to that numerical target and supplied model.
It does not represent orbit, ephemeris, atmosphere or hardware uncertainty. Nearly
flat zero intervals are reported as `nonisolated_or_underresolved_zero`, without
manufacturing an unbounded list of isolated events. Boundary roots with undefined
direction remain unresolved when a directed search requires that direction.

For nonnegative/nonpositive conditions, the engine also reports **estimated**
condition windows. Edges use event midpoint estimates and retain event brackets;
these are not conservative eligible-side intervals. Search/scan clipping is
explicit. A window midpoint that contradicts known endpoint signs reveals
unresolved crossings: the affected span becomes unknown, not a fabricated full
window. Positive and negative hidden-island regressions exercise that case.
Isolated point/tolerance contacts can exist without a finite-duration window.

Source/function unknowns are never bridged during refinement. Known events from
other covered intervals remain available, while the result status becomes unknown.
Root iteration or epoch-resolution exhaustion produces unresolved intervals.
Provider errors and exhausted global evaluation budget fail the analysis rather
than returning a partly supported success. A completed search reports
`complete_under_search_policy`; neither that status nor zero detected events
certifies discovery completeness for arbitrary callbacks.

The shared invocation context caches and counts all `EventSearch.Source.at/2`
queries and `Function.call/2` evaluations, including built-in secondary sources,
finite differences and composite children. Their combined count is bounded by
`max_evaluations`. These counters measure those APIs, not arbitrary work inside a
provider. Custom nested evaluations should use those APIs. Context is restored
on failure; nested searches inside event callbacks are rejected. No prior search's
state cache is reused.

## Finite-source occultation model

Luminary, occulter and observer positions share one origin, frame, scale and epoch.
The luminary and occulter have explicit positive spherical radii. The model checks
that the observer is strictly outside both spheres, that the spheres do not
intersect, and that foreground/background depth ordering is
resolved. Ambiguous depth ordering is unknown. It does not assume every aligned
body lies in front of the source.

Apparent angular radii and center separation define contact surfaces. Smooth
cosine-based margins avoid an undefined separation derivative at exact alignment;
umbral/antumbral size-order constraints use continuous conjunction margins rather
than discontinuous inactive branches. Tie derivatives are unavailable explicitly.
The regime is none, penumbra, umbra or antumbra. Penumbral intervals exclude the
fully contained umbral/annular interior. Degenerate zero-duration contacts are
point records, not invented positive-duration windows.

Nominal visible fraction uses uniform apparent angular-circle overlap. Umbra is
zero; annular containment leaves `1 - (occulter_angle/source_angle)^2`; separated
disks give one. Partial overlap uses the circle-lens area. This is an angular-plane
approximation, not an exact radiance integral over a limb-darkened Sun. Contact
geometry and photometric-model uncertainty are separate. Exact event roots do not
upgrade the photometric model's fidelity.

The Reflect solar-power and illumination providers are **not automatically switched**
to this event model. Their current declared shadow/beam assumptions remain visible.
A power consumer can use event brackets to partition integration after selecting a
matching source/model; partially obscured reflected-beam delivery needs its own
optical treatment.

## Extrema, composition and model validation

`Extrema.function/5` takes a quantity function, derivative step and padded state
source. It computes a central difference on actual requested epochs and verifies
that the derivative source matches the observer state at the center. Source
padding is required beyond the search window. Root timing is relative to that
finite-difference function; derivative-step sensitivity remains separate.

`Function.combine/4` requires each child to declare `:nonnegative` or
`:nonpositive` and a positive normalization scale in that child's units. Negative-
is-true children are sign-normalized. `:all` takes the minimum, `:any` the maximum.
`:not` reverses a normalized closed margin and retains equality; it is not a
strict Boolean set complement at a zero boundary. No derivative is invented for
nonsmooth combinations, and unknown children remain unknown.

Analytic checks cover Kepler node/apsis times, polynomial Hermite interpolation,
rotating ground horizons/lighting/caps, range and closest approach, limb/FOV cone
contacts, finite-source straight-line contact times, uniform-disk overlap and
annular containment. Tests also cover derivative-observed hidden roots, unobserved
grazes, near-zero candidates, source gaps, degeneracies, source matching, cache
accounting, budget cleanup, mixed inequality signs and midpoint contradictions.
None constitutes broad external-tool or flight-model validation.

## Historical verification of the standalone catalog milestone

All 5,235 fast-suite tests passed (1,143 integration/exhaustive checks excluded).
The focused event-search, existing detector/timing, demo CLI and validation-
fixture checks passed all 99 tests. The frozen mission numerical baseline command
still passes. Independent review found no remaining blocker; formatting and diff
whitespace checks pass. Full integration/exhaustive suites were not rerun.

The final search also audits all cached observations, including refinement and
nested evaluations, so a reported condition window cannot contradict observed
values outside its boundary uncertainty bands. Observed unknowns inside an event
bracket invalidate that estimate. Boundary scan points inside an already refined
bracket are normalized to the event estimate, preserving uncertainty through
window merging. Regression cases include tiny endpoint residuals outside those
bands, nested provider errors, circular/equatorial degeneracies and a central
umbra-to-antumbra size-order transition.

Adding search entry points changes the Access/Eclipse module identities captured
by candidate-refresh execution policies. The checked reference fixture report
was regenerated with only its policy fingerprint and dependent refresh ID
changed; numerical reference values and tolerances were not altered. This does
not grant the new search models the old bundle's scoped external validation.

## Consumer migration evidence

The consumer migration deliberately changes timing labels and artifact hashes.
The curated candidate-refresh **artifact contract** fixture is updated for the
shared-search boundary policy and the access/source-window digests. Frozen
external-truth data and physical tolerances are unchanged. New products remain
analysis-only; the historical external case is referenced, not evaluated or
claimed as acceptance of this search path.

Resource contact searches have their own explicit evaluation budget and cached
per-asset/model/horizon results. Source/provider errors and exhausted budgets
abort analysis; coverage gaps remain unknown. An unknown resource model does
not hide a violation demonstrated by another model.

### Migration verification (2026-11-02)

- All 5,241 fast tests passed; 1,143 integration/exhaustive checks were excluded.
- All 41 focused capability, execution-schema, validation and solar-array checks
  passed, including finite-Sun contact coverage gaps and budget failure.
- Both solar CLI integration tests passed; the full integration/exhaustive suites
  were not run.
- The frozen numerical mission baseline passed via
  `mix orbital_dynamics.mission.verify --output-dir tmp/verification_migration`.
- The event demo completed 21 functions under its declared search policy. Both
  solar studies were regenerated in `tmp/migration_solar` and
  `tmp/migration_solar_eclipse`, retaining contact evidence and energy comparisons.
- Independent review found no remaining blocker. Formatting and diff whitespace
  checks passed. The changes remain analysis support, without operations acceptance.


The migrated products now also have [independent reference comparisons](event_verification.md)
against frozen Orekit access/eclipse events and finite-Sun geometry/lighting.
Those checks distinguish root precision, interpolation and propagation sensitivity;
they do not inherit or broaden the historical external-truth registration.


[Conservative opportunity composition](conservative_opportunities.md) now connects
the shared search to mission planning. Numerical root bounds, unknown/open-contact
exclusions and declared mission timing margins remain separate evidence. An
optional `record_function_observations` selection exports all cached evaluations
for named searched functions without adding work; the planning layer uses this
to audit full-model failures observed during refinement, not just scan epochs.

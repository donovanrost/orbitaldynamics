# Sampled pointing-path constraints

The optional path-checking layer gates acquisition, holds, slews, settling,
tracking ramps and activities against declared constraints. A generic check
receives the trajectory state, full body-to-inertial orientation and an explicit
mode descriptor. It returns **supported**, **violated** or **unknown** evidence.
These are results under a declared model at tested epochs, not operational approval
or a continuous safety certificate.

## Run

```sh
mix orbital_dynamics.mission.attitude --study studies/illumination_path.json --output-dir tmp/illumination_path
mix test test/orbital_dynamics/mission_analysis/path
```

Open `tmp/illumination_path/README.md` for selected activities and the first
observed path rejection per opportunity, including rule/check names and absolute
epoch times. `report.json` contains the exact modes, configurations, captured
rule assumptions, all tested-start decisions, and sampled evidence for selected
activity paths and final transitions. The format remains the experimental
`mission_analysis.v1` report; it is not an executable plan or a registered new
campaign schema.

The new study reuses the earlier two-request attitude mission and adds synthetic
Sun/limb constraints plus a synthetic polar exclusion cap. In this declared case,
one of the two previously scheduled requests is rejected; the northern request
is scheduled approximately 61–81 seconds after the initial epoch. These are
invented requirements and reference hardware assumptions, not Reflect Orbital
specifications or real exclusion policy.

## Rules and modes

`path_constraints` is an optional study field. It declares:

- Distinct `sample_steps_s`, an uncached callback budget `max_evaluations`, and
  `max_samples_per_segment` for each tested cadence.
- Per-asset `activity_modes` mapping request IDs to mode names, a
  `transition_mode`, and a `modes` registry of parameter maps.
- Named rules with a model and its configuration.

A mode descriptor contains its name and the same parameter map for both the
service model and path rules. No meaning is inferred from labels such as “off”.
For example:

```json
{
  "reflecting": {"optical_behavior": "reflecting"},
  "off": {"optical_behavior": "unknown"},
  "blocked": {"optical_behavior": "blocked_by_assumption"}
}
```

The illumination model requires `optical_behavior: reflecting` to fulfill service.
A blocked mirror therefore cannot both clear an exclusion check and fulfill an
illumination request. The imaging model separately requires
`imaging_behavior: enabled`; `disabled_by_assumption` violates service compatibility
and any other/missing behavior is unknown. A combined camera/mirror mode must
declare both behaviors. A mirror can keep reflecting while a camera is active.

Missing mode registry entries, missing request mode selections, and models with
no `activity_mode/2` callback remain unknown when path checking is enabled.
Blocked reflection and non-reflecting back faces are explicit assumptions; no
shutter, stow or defocusing capability is invented. Mode switching is declared
instantaneous. This layer does not validate mechanisms, switching latency,
articulation or the motion required to change a hardware mode.

The new mode callbacks are optional for existing models and are required only to
support an activity through this opt-in path. The original attitude and resolution
commands keep their prior behavior when no path policy is supplied.

## Angular constraints

The built-in `angular` rule rotates a declared body axis by the full orientation
and checks minimum/maximum angles against:

- `sun`: the scene's supplied Sun direction.
- `body_limb`: angle to nadir minus the spherical apparent body radius
  `asin(body_radius / spacecraft_radius)`. Positive clearance is outside the disk.
- `inertial`: a fixed vector in the asset's declared inertial frame; this can
  express a pointing cone or exclusion cone without an Earth-specific context.

Body axes, angle bounds, frames and Sun/environment inputs are explicit. The
Sun/limb versions use `SphericalScene` and inherit its finite provider coverage and
frame approximations. There is no terrain, atmosphere/refraction or actual sensor
susceptibility model. Each check reports a degree-valued margin in its own units.

## Reflected beam and exclusion regions

The built-in `reflected_beam` rule uses a configured body-frame mirror normal,
its actual sampled orientation, supplied Sun direction and spherical body. For
spacecraft-to-Sun unit vector `s` and mirror normal `n`, the central reflected ray is

```
direction = -s + 2 dot(s, n) n
```

The near intersection of that ray with the sphere is reported as a rotating-body
latitude/longitude. A central ray miss is **not** sufficient to clear an exclusion:
the reflected solar cone can still intersect the body. The cone half-angle is the
declared solar angular radius plus an explicit beam-padding angle.

Exclusion regions are spherical surface caps defined by latitude, longitude and
surface radius in kilometers. For cap angular radius `gamma`, a ball centered at
the cap's surface center with radius `2 R sin(gamma/2)` encloses that cap. Viewed
from the spacecraft, this ball supplies a conservative angular envelope. A guard
is violated if the reflected cone can overlap that envelope and the cap cannot
be proven entirely beyond the visible surface. The rule also checks whether the
entire cone misses the apparent body disk. A small numerical angular guard is
recorded in the rule assumptions.

This deliberately permits false-positive rejections: an enclosing ball can overlap
the cone when the actual cap does not. `possible_cone_overlap_with_region_bound`
means a conservative criterion was violated, not that actual illumination or a
particular irradiance was established. There is no delivered-flux threshold,
finite-aperture/deformation/scatter model, terrain, clouds, or validated pointing
uncertainty bound. The padding angle is a declared assumption, not a calibrated
physical error budget. Mirror normals and pointing mounts must describe the same
physical layout; no automatic hardware-layout inference is performed.

Full solar-disk occultation can remove solar reflection in this ideal model.
Partial occultation retains the whole cone conservatively; the old point-Sun
cylindrical shadow result is not used to claim no reflection. Unknown back optics
remain unknown whenever any part of the finite Sun could reach the back face,
even when the Sun-center incidence is slightly positive. Explicitly non-reflecting
back optics can remove a fully backside disk; partial front illumination retains
the whole cone as an overestimate. The example assumes a two-sided reflecting
mirror, including during transitions, solely to make that assumption reviewable.

## Scheduling and sampling evidence

A candidate must pass the declared path checks on its incoming transition, its
activity, and its transition to any already selected successor. This complements
the earlier kinematic checks. Earlier insertions cannot introduce an unchecked
successor slew. Once selection finishes, final transitions are rebuilt and checked
again; their evidence reflects the final graph rather than decision history.

Activities evaluate required orientation directly from the original model session
at path-sample epochs. Transitions evaluate the constructed motion, including all
phase endpoints and rest holds. Both sides of an activity/transition boundary are
checked with their respective modes. There is no linear quaternion interpolation
or assumption that only the central ray matters.

Every requested cadence is evaluated using the same captured check sessions.
The example uses 5, 1 and 0.25 seconds. Any observed violation on **any** tested grid
vetoes a candidate; unknown evidence cannot support selection. The report flags
`changes_across_tested_steps` when classifications differ. A finer grid is not
assumed to contain every point from a coarser grid, so coarser violations are
retained too. Agreement remains a comparison of sampled classifications, not a
proof of continuous clearance or a bound on event time.

A level stops at its first unsupported sample and labels that trace as a prefix;
its first issue includes epoch, scope, mode, rule/check status and available
metrics. A supported level covers all requested samples and records its largest
actual tested interval. Sample-limit or epoch-precision failures remain unknown.
Provider failures and shared evaluation-budget exhaustion abort analysis rather
than returning a partially supported plan.

Rule and service-mode results are cached by asset, rule/request, epoch, full
orientation where applicable, and complete mode descriptor. A changed insertion
therefore cannot reuse a check for the same epoch with a different orientation or
mode. `max_evaluations` covers uncached rule and service-mode callbacks; ordinary
geometry, attitude and refinement evaluations retain their separate counters.
Preparation runs once per asset/rule and captures JSON-safe assumptions separately
from the opaque runtime session. Model callbacks and state sources must remain
consistent under those captured assumptions.

Path coverage starts at the declared initial attitude and ends with the last
scheduled activity. There is no inferred pre-initial path, terminal braking/idle
orientation, or path for an asset with no selected activity. `no_scheduled_path`
is not a clearance result. Constraints not declared in the policy—such as real
communications requirements, collision avoidance or terminal safing—are not assessed.

## Extension and verification boundary

`Path.Check` supplies `prepare/3` and `evaluate/4`; it does not depend on a surface
target or particular mission type. Models implement `activity_mode/2` to interpret
their own mode parameters. New programmatic checks can use other contexts and
bodies; the JSON reference adapter deliberately permits only the two built-in rule
models, without dynamically loading module names from input strings.

Tests cover arbitrary-body reflection and angular geometry, finite-cone versus
central-ray misses, cap visibility, partial/full solar occultation, unknown back
optics, shared service/optical modes, structured unknown parameters, coarse/fine
missed dips, orientation-sensitive cache identity, captured sessions, outgoing
insertion checks, final transition evidence, bounded work, unknown coverage and
source errors, plus the real reference and CLI. These are analytic/internal checks;
no independent external beam-envelope or path-safety validation is claimed.

Validation for this slice: all 5,161 fast-suite tests passed (1,135 integration/
exhaustive tests excluded); all 82 focused analysis and mission CLI checks passed.
The full path example completed and produced one selected activity. Independent
review findings about finite-Sun back-face exposure and structured unknown-mode
parameters were resolved with regressions; final review found no remaining
blocker. Formatting and diff whitespace checks passed. Full integration/exhaustive
suites were not rerun.

The [frozen numerical baseline](verification_baseline.md) adds separately scoped
independent attitude/beam comparisons and frozen internal planner scenarios.
Its finite cases do not promote these results to continuous or flight validation.

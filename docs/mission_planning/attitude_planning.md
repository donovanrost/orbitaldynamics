# Acquisition, tracking and activity transitions

The optional attitude-planning path adds explicit body orientation and angular
motion assumptions to the existing mission-independent planner. It answers whether
the sampled required pointing profile and a constructed transition path satisfy
declared rate, acceleration and settling limits. This is a kinematic analysis,
not achieved attitude, actuator simulation, or validation for Reflect Orbital.

## Run

```sh
mix orbital_dynamics.mission.attitude --study studies/illumination_attitude.json --output-dir tmp/illumination_attitude
mix test test/orbital_dynamics/mission_analysis/attitude
```

Open `tmp/illumination_attitude/README.md` for selected activities, sampled tracking
rates/accelerations, acquisition and transition times, and rejection summaries.
`report.json` preserves the complete mission/study inputs, profile quaternions,
angular velocity/acceleration, tested-start decisions and constructed motion phases.
It remains an experimental `mission_analysis.v1` analysis report, not a command
sequence, approved mission plan, or new registered campaign artifact.

The example uses a synthetic two-request illumination mission in
`studies/reference_attitude.json`. Its controller limits—2°/s rate, 0.2°/s²
acceleration and 2 seconds of settling—are invented reference assumptions. They
are not Reflect spacecraft specifications. Existing mission and trade/resolution
commands retain their original policies unless attitude planning is explicitly
enabled.

## Explicit initial state, mounts and roll

The study names its mission file relative to the study file and declares:

- Observation and integration resolution plus the existing window-refinement
  settings. The same checked state sampler is used for geometry and pointing.
- Per-asset angular-rate norm, angular-acceleration norm, and settling dwell.
- A known initial quaternion, inertial angular velocity, epoch, frame and time
  scale, or `initial: null` for unknown.
- Per-model pointing configuration. The surface models require a fixed
  `body_to_payload_quaternion` and `roll_reference_inertial` vector.
- Profile cadence, derivative interval, candidate-start spacing, start-search
  budget, and additional model-evaluation budget.

Quaternions use Hamilton `[w,x,y,z]` active **body-to-inertial** rotations.
Angular velocity and acceleration are three-component inertial vectors, in
**degrees/second** and **degrees/second²**. The initial state must match the
asset's frame and time scale; no conversion is implicit. The Earth reference
adapter accepts explicit J2000/UTC metadata. The generic core accepts other
consistent inertial frames and time scales. An initial state can predate the
trajectory; its persistence is then an ideal control assumption, not a measured
state estimate or covariance propagation.

The illumination normal or camera boresight alone does not determine a full
spacecraft attitude. For both built-in surface models, payload +Z follows that
direction; payload +X follows the projection of the declared inertial roll
reference onto the perpendicular plane. The mounting transform then maps body
axes through payload axes to inertial axes. If the roll reference becomes too
nearly parallel to the pointing direction, orientation remains unknown rather
than choosing a hidden replacement rule.

These profiles assume a rigidly mounted payload and whole-body motion. Articulated
mirrors, gimbals, multiple independently controlled pointing groups, free-roll
optimization, and flexible structures are not modeled. Different missions can
supply their own full orientation through the optional `Model.pointing/3`
callback; the core has no illumination-versus-imaging scheduling branch. The
callback uses the original captured model session and returns `Pointing`, an
explicit unknown, or an error. The model owns its configuration and roll semantics.

Setting an example asset's `initial` value to JSON `null` preserves its geometric
opportunities but leaves acquisition unknown and schedules no activities on that
asset. Missing attitude configuration, missing profile callbacks, missing profile
configuration or derivative coverage also cannot produce a supported activity.
Provider errors abort analysis; they are not relabeled as physical infeasibility.

## Activity profile checks

For each tested start, the planner samples the required full orientation through
the activity, including its start and end. Central shortest-quaternion differences
estimate inertial angular velocity; differences of adjacent rate estimates give
angular acceleration. With derivative interval `h`, a point needs orientations at
`t-2h`, `t-h`, `t`, `t+h`, and `t+2h`. Data outside the trajectory are not extrapolated.
Unresolvable floating-point epoch differences remain unknown rather than implying
zero motion. Quaternion sign changes do not represent physical rotation.

Each sampled profile point must satisfy both the model's existing physical checks
and the asset's rate/acceleration norms. Actual epoch differences are used in the
numerical denominators. The derivative interval must resolve the declared rate
envelope (`2h × maximum rate < 180°`), but actual fast motion, aliasing and internal
violations can still remain undetected. This is sampled evidence, not an
instantaneous derivative bound or continuous tracking certificate.

`profile_step_s` controls internal activity sampling. `derivative_step_s` is a
separate control from both the profile cadence and the existing model's fixed
tracking lookback. The model's mirror-normal/boresight-rate check still applies;
the new body profile additionally includes the declared roll and mount geometry.
Activity records contain the frame, sampled quaternions, inertial rates and
accelerations. Rate/acceleration agreement should be checked at finer settings
before treating a close-to-limit result as useful operational evidence.

## Constructed transitions

The planner does not assume tracking activities end at rest. Given source and
destination quaternions and inertial angular velocities, it constructs:

1. Constant-axis braking from the source tracking velocity to rest.
2. A rest hold if time is available.
3. A shortest-axis triangular or trapezoidal rest-to-rest slew.
4. The declared rest settling dwell.
5. Constant-axis acceleration into the destination tracking velocity, ending at
   its required orientation and velocity.

For rate bound `v`, acceleration bound `a`, and rest-to-rest angle `theta`:

```
triangular slew:  T = 2 sqrt(theta / a)          when theta <= v²/a
trapezoidal slew: T = theta / v + v/a           otherwise
```

Angles are degrees and times seconds. Braking takes `|omega_source|/a` seconds;
ramping takes `|omega_destination|/a`. Their orientation changes are included in
the required rest-slew endpoints. In every constructed phase angular velocity
and acceleration are collinear, so integrating their rotation vector within that
phase gives the orientation. General noncommuting motion is not assumed to have
this property. Reported terminal orientation and rate residuals expose numerical
closure at the destination.

The motion phases are a constructive path with an analytic rate/acceleration
envelope under these assumptions, not a globally minimum-time solution. Angular
acceleration can change instantaneously: jerk, inertia, actuator torque and
saturation, momentum storage, disturbances, structural response and achieved
settling behavior are outside the model. The settling dwell occurs at rest
before ramping into tracking; it is not a dynamics prediction of settling while
following the target.

**Intermediate transition paths are not screened against Sun/keep-out constraints,
unintended ground illumination, occultation or communication requirements.** In
particular, a mirror could illuminate other locations during a kinematically
supported slew. The motion result supplies no optical safing or execution authority.

## Scheduling and explanations

The planner preserves value-first greedy request selection and declared static
resource budgets. It searches explicit candidate start times within each refined
opportunity. The existing `asset_separation_s` remains a minimum activity gap
alongside the required transition time; it is no longer the only transition test.
It does not add a separate idle period on top of the kinematic transition.

Every candidate checks acquisition or its predecessor transition, the sampled
tracking profile, and the transition to any already selected successor. Thus an
earlier insertion cannot invalidate a higher-priority activity already selected
later. The final transition graph is rebuilt chronologically, so its evidence
reflects accepted insertions rather than stale selection history.

Reasons distinguish insufficient incoming/outgoing time, sampled rate/acceleration
violations, physical rejection at an additional activity sample, resource or asset
conflicts, and unknown pointing/acquisition evidence. If no tested start works,
the result is `infeasible_on_tested_start_grid`, not proof that no continuous-time
schedule exists. Truncated searches remain unknown. No initial pose is synthesized
from the first desired pointing direction.

`max_candidate_starts` bounds each opportunity's search. `max_evaluations` bounds
uncached pointing calls and additional activity-physical-check calls across the
attitude scheduler; its counter is `attitude_planning.model_evaluation_count`.
Ordinary geometric grid/refinement calls and the core's final endpoint checks
retain their separate limits and counters. Profiles cache results by asset,
request and numeric epoch. Budget exhaustion aborts the analysis instead of
returning a partially checked schedule. Source samplers/model callbacks must stay
deterministic under the captured assumptions.

Slew energy is not charged automatically, and static activity costs are not a
power or thermal model. There is no global optimization, rolling repair or
simultaneous independently controlled payload scheduling in this slice.

## Optional path constraints

The separate [path-checking policy](path_constraints.md) now evaluates declared
rules during activities and transition phases. It includes explicit shared modes
and reflected solar-cone exclusion bounds. The original attitude example has no
path policy and retains its kinematic-only behavior. Enabling path checks does
not add unspecified constraints or continuous certification.

## Example and verification

With the checked-in assumptions, the first request runs approximately **91–131
seconds** after the initial epoch and the second **163–183 seconds**. The first
acquisition needs about **89.46 seconds**; the subsequent transition needs about
**30.72 seconds**, against available gaps of 91 and 32 seconds. The earlier
geometry-only result would not account for these motions.

Tests cover Hamilton and antipodal conventions, mounting/roll geometry, analytic
triangular/trapezoidal times, nonzero endpoint rates, phase rate/acceleration
bounds and terminal closure, sampled analytic tracking derivatives, small-angle
and epoch precision, explicit acquisition/unknown behavior, tracking rejection,
predecessor/successor insertion, final graph recomputation, source errors and
bounded searches, resource separation, both built-in pointing callbacks, replay,
and the reference CLI. The existing numerical baseline and resolution tests still
apply to their original evidence boundaries. There is no new independent external
attitude-dynamics or flight validation.

Validation for this slice: all 5,146 fast-suite tests passed (1,134 integration/
exhaustive tests excluded); all 66 focused analysis and mission CLI checks passed.
The two-request example was exercised, and formatting/whitespace checks passed.
Independent review confirmed the quaternion/kinematic conventions and insertion
checks. Its shared-resolution input-validation finding was fixed and covered by
a tagged-error regression. Full integration/exhaustive suites were not rerun.

The [frozen numerical baseline](verification_baseline.md) adds separately scoped
independent attitude/beam comparisons and frozen internal planner scenarios.
Its finite cases do not promote these results to continuous or flight validation.

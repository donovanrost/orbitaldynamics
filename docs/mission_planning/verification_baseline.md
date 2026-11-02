# Reference mission numerical baseline

The current mission-analysis work is packaged as a frozen, reproducible numerical
baseline. It combines independent calculations and internal scenario regressions
without merging their evidence claims. It remains analysis software using invented
hardware assumptions; a passing baseline is not flight readiness or an approval
to execute a plan.

## Run the baseline

```sh
mix orbital_dynamics.mission.verify --output-dir tmp/verification_baseline
```

Open `tmp/verification_baseline/README.md` for the summary and `report.json` for
per-case measurements, tolerances, source identities and scope. The command runs
offline against verified checked-in bytes, writes discrepancies, and fails if any
numerical group or frozen scenario fails. It uses experimental report format
`mission_verification_baseline.v1`; no existing validation registry, artifact
schema or propagator validation level is promoted.

## Evidence inventory

| Group | Frozen coverage | What it establishes |
| --- | --- | --- |
| Existing orbit baseline | One 600 km J2 orbit,301 epochs over 6,000 s | Matched-input orbit/spherical geometry agreement with Orekit |
| Orientations | 45 direction/roll/mount cases | Actual production pointing adapter agrees with library rotations |
| Tracking profiles | 12 fixed-axis/two-axis cases | Quaternion finite-difference rates/accelerations agree with library calculations |
| Transition construction | 18 cases, including short-gap rejection and nonzero endpoint rates | Declared construction timing agrees with an independent library-angle/Brent solve |
| Quaternion phase ODE | 17 feasible cases,4,308 samples | Production phase evaluation agrees with separate ODE integration and reaches requested endpoints at physical input gaps |
| Beam geometry | 169 static snapshots, including grazing and partial/full eclipse cases | Reflection/intersection agreement and no observed false-clear among independently sampled overlaps |
| Planner scenarios | Acquisition/tracking; path rejection; unknown optics | Frozen internal end-to-end behavior, not external validation |

The attitude/path physical inputs, generator, locked dependencies and independent
outputs live in
[`priv/validation/attitude_path_orekit`](../../priv/validation/attitude_path_orekit/README.md).
All relevant bytes are bound by a checked-in checksum inventory whose digest is
pinned in code. The earlier orbital bundle has its own independent identity.
The scenario inputs are copies frozen in the new bundle, rather than references
to mutable example-study files.

## Measured comparisons

Acceptance tolerances were fixed before comparison and retained when the initial
zero-rotation case failed. Representative maximum differences after the fix are:

| Measurement | Observed maximum | Acceptance tolerance |
| --- | --- | --- |
| Orientation quaternion sign-invariant norm | About 6e-16 | 1e-12 |
| Rotated vector norm | About 1.1e-15 | 1e-11 |
| Constructed transition time | About 2.85e-14 s | 1e-8 s |
| Quaternion ODE versus production norm | About 2e-15 | 1e-10 |
| Angular velocity versus ODE | About 1e-14 deg/s | 1e-8 deg/s |
| Profile rate versus library estimate | About 1.4e-13 deg/s | 1e-8 deg/s |
| Profile acceleration versus library estimate | About 2.9e-12 deg/s² | 1e-7 deg/s² |
| Spherical ray intersection | About 1.7e-8 km (0.017mm) | 1e-7 km (0.1mm) |
| Reflected direction norm | About 1.6e-15 | 1e-12 |

Terminal ODE orientation/rate, initial conditions and sample epochs have separate
explicit checks in the report. Quaternions are compared with sign equivalence,
so an antipodal representation is not treated as a different orientation.

The tracking-profile comparison also measures finite-step error against analytic
instantaneous values. In this corpus, that error reaches approximately 0.000884°/s
in rate and 0.0000801°/s² in acceleration. Agreement with another finite-difference
implementation therefore does not eliminate truncation error or establish
instantaneous feasibility for a close-to-limit activity.

## Discrepancy found and corrected

The first comparison found that identical non-axis-aligned quaternions could
produce an inverse-product roundoff rotation. That created a fictitious
approximately 1.9939141e-8-second rest slew in the zero-angle fixture, exceeding the
predeclared 1e-8-second timing tolerance. At a zero-gap boundary it could also
incorrectly reject a no-motion transition.

`Quaternion.delta` now handles exactly equal normalized quaternions and their
antipodes as zero separation **before** multiplying by an inverse. This is not an
angular cutoff: genuine 1e-13-degree increments remain measurable. Regression tests
cover zero-gap and exact-settling cases as well as the small nonzero rotation.
Controls and external ODE outputs were regenerated after the fix; tolerances
were not widened to make the discrepancy disappear.

## Conservative beam evidence

The independent beam search samples each cap directly using library sphere
intersections, without the production enclosing-ball rejection shortcuts. It
checks both direct visible solar-ray witnesses and, where applicable, the declared
padded cone. No observed overlap in this corpus was cleared by production.
The report separately counts geometric witnesses for raw snapshots and witnesses
in declared-reflecting modes.

Twelve guard rejections had no sampled cone witness. This is a useful conservatism
indicator, not twelve proven false positives: a finite grid can miss an overlap.
Per-case output retains the closest sampled cap angle and declared cone width for
investigation. No statistical probability or exhaustive no-false-clear claim is
inferred from the seeded finite corpus.

## Reproduction and development

The bundle README gives commands to regenerate the external outputs in a pinned
Docker environment. A second run produced identical bytes for all five output
files. Java regeneration needs Docker/network; ordinary checks do not.
`make_inputs.py` and `export_phases.exs` are baseline-authoring tools, not automatic
verification steps. Updates require reviewing changed physical inputs, exported
controls and independent results before intentionally changing hashes or fixtures.

Focused checks:

```sh
mix test test/orbital_dynamics/mission_analysis/attitude_path_check_test.exs
mix test test/mix/tasks/orbital_dynamics.mission.verify_test.exs
```

The second command exercises the complete baseline and is tagged integration.
The numeric bundle checks are ordinary fast tests. Long/full-suite checks remain
available through the project's existing test tiers.

## Remaining boundaries

The independent solver checks the chosen motion construction, not globally optimal
SO(3) control. The ODE controls come from production, so their independently
integrated orientation is not an independent choice of maneuver; target-state and
physical-time gates prevent that comparison from self-confirming wrong endpoints.
Source and target frames are matched by assumption, with dummy TAI epochs for new
snapshot calculations. Supplied Sun directions, real Earth orientation, actual
mode mechanisms and hardware limits are not validated by these cases.

No atmosphere, cloud, terrain, scattering, finite-aperture/deformation, actuator
inertia/torque, flexible-body response, achieved attitude, mode-switch latency,
terminal idle behavior or continuous path safety is added. Frozen planner outcomes
remain regression evidence. Real mission requirements and independent physical
validation are still needed before these results can support operations.

Validation for this milestone: all 5,165 fast-suite tests passed (1,136 integration/
exhaustive tests excluded); all 86 focused analysis/mission CLI checks passed.
The baseline command passed, all five independent outputs reproduced byte-for-byte,
and formatting/diff whitespace checks passed. Independent review findings about
physical endpoint/time gates and non-vacuous scenario identity were resolved;
final review found no remaining blocker. Full integration/exhaustive suites were
not rerun.

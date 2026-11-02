# Frozen attitude and path numerical references

This bundle supplies independently generated numbers for the declared ideal
models and separately frozen internal planner scenarios. It does not validate
Reflect Orbital hardware, actual optical mode mechanisms, continuous safety,
source ephemerides, or frame/time transformations.

## Reproduce the numerical outputs

From the repository root:

```sh
priv/validation/attitude_path_orekit/generate.sh tmp/independent_replay
cmp priv/validation/attitude_path_orekit/orientation-reference.csv tmp/independent_replay/orientation-reference.csv
cmp priv/validation/attitude_path_orekit/profile-reference.csv tmp/independent_replay/profile-reference.csv
cmp priv/validation/attitude_path_orekit/motion-reference.csv tmp/independent_replay/motion-reference.csv
cmp priv/validation/attitude_path_orekit/motion-samples.csv tmp/independent_replay/motion-samples.csv
cmp priv/validation/attitude_path_orekit/beam-reference.csv tmp/independent_replay/beam-reference.csv
```

Generation requires Docker/network. It uses the same pinned ARM64 Maven/Java
container as the orbit baseline, Orekit 13.1.7, and Hipparchus 4.0.3. Every JAR is
checked against `dependencies.lock`; dependencies and classes live in a disposable
directory. No Python, Elixir, current ephemeris download, or planner invocation is
used during Java replay. A second run reproduced all five output files byte-for-byte
in this pinned environment. This is not a promise of bitwise identity on every
host/runtime combination.

Normal verification is offline:

```sh
mix orbital_dynamics.mission.verify --output-dir tmp/verification_baseline
```

`SHA256SUMS` binds generator sources, inputs, outputs and frozen scenarios. Its
own digest and exact file inventory are pinned in `AttitudePathCheck`. Verification
checks bytes before consuming them. It does not automatically regenerate references
or change tolerances when a result fails. README prose is outside the numerical
manifest. Content identity is not an authenticity/signature check.

## Inputs and independence

| Files | Role |
| --- | --- |
| `orientation-input.csv` | 45 direction/roll/mount inputs, including principal-axis cases |
| `profile-input.csv` | 12 fixed-axis and noncommuting two-axis profile laws with derivative intervals |
| `motion-input.csv` | 18 physical endpoint orientations/rates, time gaps and angular limits |
| `beam-input.csv` | 169 spherical-body, Sun, mirror, region and optical-mode snapshots |
| `phase-input.csv` | Production-exported phase times and angular accelerations; this is not external truth |
| `*-reference.csv`, `motion-samples.csv` | Independent Java results |
| `mission.json`, `*-study.json`, `scenarios.json` | Three frozen internal end-to-end scenario regressions |

`make_inputs.py` creates physical inputs using explicit edge cases and seed 731904;
its code and generated CSV bytes are both checked in. Recreating physical inputs is
an intentional baseline change, not a normal verification step. It does not use
Elixir outputs. Quaternion input construction merely defines orientations; the
reference implementation independently applies them using library operators.

`export_phases.exs` uses production `Motion.transition` to export controls from the
physical motion inputs. To inspect/recreate controls, copy `motion-input.csv` to a
temporary directory and run the script with that directory as its only argument.
The production controls must match the frozen controls within 1e-10 in their stated
seconds/degree-per-second-squared units. Altering controls requires regenerating the
ODE reference and reviewing the resulting endpoint evidence.

### Rotation and profile comparisons

Hipparchus builds the payload orientation from pairs of vectors and composes the
mount using `RotationConvention.VECTOR_OPERATOR`. The conversion from library
quaternion coordinates to the application's Hamilton active `[w,x,y,z]` convention
negates the library vector part. The generator asserts a positive-Z 90° convention
case. Production comparison exercises `Pointing.from_direction`, including the
mount-composition boundary, and compares quaternion and rotated-vector results.

Fixed-axis and two-axis profile laws are evaluated by library composition at the
same finite-difference epochs as production. Separate analytic instantaneous rates
and accelerations expose truncation error. Library agreement does not mean the
finite-difference estimates equal instantaneous values.

### Motion comparisons

A Hipparchus Brent solver finds the duration at which the rate/acceleration-bounded
rest-slew reachable-angle law meets the library-computed angle. Independent library
composition includes braking/ramping endpoint offsets. This checks the declared
construction, not the globally optimal SO(3) control problem.

A separate Dormand–Prince 8(5,3) ODE integration evolves Hamilton quaternion and
inertial angular velocity under the **production-exported controls**. Its scalar
absolute/relative tolerances are 1e-13, maximum step 0.25 s. Integration restarts with
local interval time to resolve tiny final remainders; state propagates continuously
across subintervals and phases. Outputs include phase endpoints and samples at
most 0.25 s apart. The verifier compares samples with production and checks independent
source/target orientation, rate and physical input gap, plus complete ID/epoch
coverage. It never treats production-reported availability as the time oracle.

### Beam comparisons and witnesses

Library half-turn rotation computes ideal reflection; Orekit's spherical
`OneAxisEllipsoid` line intersection supplies the nearest surface point, followed
by a forward-ray test. Body rotation and geodetic conversion use library frame
transforms. Orekit's finite-source `OccultationEngine` supplies visibility angles.
The artificial source is at distance 1e18 m with the declared angular radius, matching
the parallel-ray model to the comparison precision. The full-eclipse case uses an
explicit 0.1° source offset: exact collinearity leaves the library's limb plane
undefined and is not silently perturbed at runtime.

For each region, the generator directly samples its spherical cap at 16 radial
rings and 128 azimuths, plus the center (2,049 points). Visibility is checked using
Orekit's first intersection, not the production cap/enclosing-ball shortcuts.
It counts modeled-cone witnesses and direct solar witnesses. Direct witnesses
must have an unocculted incident ray inside the unpadded solar disk and a known
reflecting face. The guard may never clear those sampled overlaps for a declared
reflecting mode. In the two-sided modeled-cone subset, the padded cone also gates
false-clear checks. Inactive/unknown-mode raw geometry is not misclassified as
active exposure.

No-witness results are not proof of non-overlap. Guard rejections without sampled
witnesses are recorded for investigation, not labeled proven false positives.
There is no minimum-flux, finite-aperture, scattering/deformation or real pointing
error model. Dummy TAI epochs and matched inertial coordinates are used throughout.

References: [Hipparchus Rotation API](https://www.hipparchus.org/apidocs/org/hipparchus/geometry/euclidean/threed/Rotation.html),
[Orekit sphere/ellipsoid intersections](https://test.orekit.org/site-orekit-13.1.2/apidocs/org/orekit/bodies/OneAxisEllipsoid.html).

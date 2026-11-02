# Matched-input Orekit baseline

This independent numerical check covers the single illumination reference orbit
and its spherical geometry. It is not a registered general external-truth case,
a validation of Reflect Orbital operations, or an optics/attitude validation.
See [trade studies](../../../docs/mission_planning/trade_studies.md) for measured
errors, acceptance tolerances and the exact evidence boundary.

## Inputs and implementation

- `case.properties`: Earth/J2 constants, initial circular elements and target.
- `environment.csv`: elapsed SI seconds, Earth angle, and supplied Sun directions
  from the existing content-verified campaign provider.
- `inputs.json`: complete baseline configuration and environment provenance.
  Host-dependent file paths are omitted; content identities remain.
- `MissionBaseline.java`: Orekit 13.1.7 element conversion, adaptive
  Dormand–Prince 8(5,3) integration, topocentric range/elevation, target solar
  elevation, off-nadir geometry and cylindrical shadow evaluation.
- `dependencies.lock`: exact Maven JAR hashes for Orekit and Hipparchus 4.0.3.
- `generate.sh`: pinned ARM64 Maven/Java image and dependency verification.
- `reference-output.csv`: independent output, 301 sampled rows over 6,000 seconds.
- `SHA256SUMS`: source/input/output content manifest pinned in `BaselineCheck`.

The position/velocity adaptive absolute tolerances are 1e-5 m and 1e-8 m/s,
relative tolerances 1e-13, and step bounds 0.001–30 seconds. Orekit supplies
Newtonian gravity and the explicit J2 perturbation. There is no drag.

EME2000 axes are identified with repository J2000 axes for this matched-input
comparison. Orekit uses a dummy TAI epoch and elapsed seconds. Supplied Sun and
Earth-angle rows are evaluated at the exact sample epochs; no solar ephemeris,
Earth-orientation or time conversion is inferred by Java. The input inclination
and RAAN are imported estimates, so this does not check the SSO design equation.

## Verify and reproduce

From the repository root, ordinary verification is offline:

```sh
mix orbital_dynamics.mission.check_baseline --output tmp/baseline_check.json
```

To reproduce the independent output (requires Docker/network; downloads only
hash-verified JARs into a disposable directory):

```sh
priv/validation/mission_analysis_orekit/generate.sh tmp/orekit_reference.csv
cmp priv/validation/mission_analysis_orekit/reference-output.csv tmp/orekit_reference.csv
```

To inspect whether current production input construction still matches the saved
physical inputs, export into a temporary directory:

```sh
mix run priv/validation/mission_analysis_orekit/export_inputs.exs tmp/baseline_inputs
diff -u priv/validation/mission_analysis_orekit/case.properties tmp/baseline_inputs/case.properties
diff -u priv/validation/mission_analysis_orekit/environment.csv tmp/baseline_inputs/environment.csv
diff -u priv/validation/mission_analysis_orekit/inputs.json tmp/baseline_inputs/inputs.json
```

`export_inputs.exs` uses the reference adapter only to obtain design and
source-bound environment inputs. It does not export states or geometry to Java.
Updating this baseline requires reviewing changed physical inputs and independent
results, regenerating the checksum manifest, and intentionally updating its pinned
digest in `BaselineCheck`. The tolerances are fixed acceptance thresholds, not
values automatically fit to a new result.

Orekit references:
[project and documentation](https://www.orekit.org/),
[J2-only perturbation API](https://test.orekit.org/site-orekit-13.1.2/apidocs/org/orekit/forces/gravity/J2OnlyPerturbation.html),
[topocentric frame API](https://test.orekit.org/site-orekit-13.0.3/apidocs/org/orekit/frames/TopocentricFrame.html).

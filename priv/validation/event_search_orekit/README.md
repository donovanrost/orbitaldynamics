# Independent finite-Sun geometry reference

This frozen bundle uses Apache Orekit 13.1.7 and Hipparchus 4.0.3. It imports no
project state samples, event times, lighting fractions or production formulas.
`cases.csv` declares two synthetic straight flybys, one crossing total shadow and
one crossing annular shadow. They exercise geometry, not dynamically feasible
orbits. The 0.1 km off-axis offset avoids the exact-syzygy limb-plane degeneracy.

Coordinates and radii are km in the input; Java explicitly converts to SI. The
body is spherical, centered at the EME2000 origin, and the spherical Sun is fixed
on +X. A dummy TAI epoch supplies time differences; no time/frame conversion,
external ephemerides or EOP are tested. All states lie outside nonoverlapping
spheres with the central body wholly in front of the Sun.

Orekit `EclipseDetector.withPenumbra()` and `.withUmbra()` supply outer/total
contact functions. The annular internal-contact scalar is the sum of separation
and body angular radius minus source angular radius, using Orekit
`OccultationEngine` angles. Hipparchus Brent solves strict sign flips scanned at
0.05 s, with 1e-10 s absolute tolerance. The offline verifier requires two outer
and two inner contacts in each case, with umbra only in `total` and antumbra only
in `annular`. These checks do not establish discovery of arbitrary grazes.

Lighting fractions use **numerical vertical-strip integration** of overlapping
angular disks, with a sin-squared change of variable at each integration segment.
They do not copy the production analytic lens-area expression. Hipparchus uses
16-point Gauss integration, 1e-11 relative / 1e-16 absolute area tolerances, and a
200,000-evaluation ceiling. Fractions describe uniform apparent angular disks,
not a spherical radiance integral or limb-darkened Sun. Expected power multiplies
that fraction by Orekit's center-ray +X panel cosine and 1000 W/m2 (1 m2 panel,
unit panel/bus efficiency). This checks solar-consumer wiring, not hardware.

Samples include a 0.25 s grid, both sides of each contact at +/-1 ms, contact
estimates and interval midpoints. Regime labels exactly on a contact are
numerically ambiguous; the verifier excludes label comparison only within its
explicit 1e-10 rad contact band, while still checking angles/fraction/power.

Regenerate separately from routine checks:

```sh
priv/validation/event_search_orekit/generate.sh tmp/event-reference
cmp tmp/event-reference/reference-output.json priv/validation/event_search_orekit/reference-output.json
cmp tmp/event-reference/leo-reference.json priv/validation/event_search_orekit/leo-reference.json
```

Docker is needed only for regeneration. The image digest and dependency JAR
SHA-256 identities are pinned; the generator records its Java runtime. A changed
reference requires reviewing inputs, source, tolerances and results, then updating
the content manifest and verifier pin deliberately. Ordinary tests and
`mix orbital_dynamics.events.verify` read only frozen local data.

Primary implementation source: the Apache Orekit 13.1.7 sources JAR published at
https://repo.maven.apache.org/maven2/org/orekit/orekit/13.1.7/orekit-13.1.7-sources.jar
(`EclipseDetector.java` and `OccultationEngine.java`). No source code from that
JAR is copied into this generator.

## Finer independent LEO reference

`OrekitTruthGenerator.java` is a byte-for-byte copy of the generator from the
existing six-hour external-truth bundle. The original sealed bundle is unchanged.
`leo-fine.properties` changes its case ID, generation timestamp, RK4 step and
native output grid to 2.5 s. Every other physical, time/frame, detector and solver
input matches the original case. `retain_grid.py` retains only exact 10 s state
anchors, with no interpolation or computed values; all event times remain the
Orekit solver results. The retained grid is recorded in `leo-reference.json`.
Its `source_identity_sha256` identifies the copied Java generator; this bundle's
pinned content manifest binds the generator, configuration, grid-filter source
and final reference together.

The original 10 s and new 2.5 s Orekit trajectories differ by roughly 6 cm over
six hours, showing why a tight matched-integrator regression tolerance must not
be confused with an accuracy bound. Production 10 s propagation is compared
against the original 10 s reference. Production 5 s and 2.5 s propagation is
compared against the finer independent reference, with the same 1 cm / 1e-5 m/s
state tolerances. Event residuals use the corresponding independent reference;
no assumption that a finer project run is truth is made. State differences from
the original 10 s reference are also reported as sensitivity, without an
acceptance status or an inferred physical error bound.

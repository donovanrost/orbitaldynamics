# Independent checks for shared event search

The migrated production event products now have an offline comparison against
independent Orekit results. Finite-Sun geometry, contacts and solar power also
have frozen independent references. This is numerical evidence for specific
matched models; it does not promote the detectors' general validation level or
establish operations acceptance.

## Run the checks

```sh
# Fast finite-Sun reference checks, without Java, Docker or network access:
MIX_ENV=test mix orbital_dynamics.events.verify \
  --group finite-sun --output-dir tmp/event_verification_finite

# Full six-hour propagation/interpolation sensitivity comparison plus finite Sun:
MIX_ENV=test mix orbital_dynamics.events.verify --output-dir tmp/event_verification

# Focused default-loop tests (the long LEO check is excluded):
mix test.fast test/orbital_dynamics/validation/event_search \
  test/mix/tasks/orbital_dynamics.events.verify_test.exs

# Explicitly run the longer six-hour integration test:
mix test test/orbital_dynamics/validation/event_search/leo_check_test.exs --include integration
```

The CLI writes `README.md` and `report.json`. It exits unsuccessfully for a failed
comparison; inspect the retained per-event or per-sample diagnostics. Missing,
extra and misordered events fail identity matching before residuals can pass.
An incomplete production search cannot supply successful boundary comparisons.
Search/provider errors produce failed group evidence. Output paths and final-file
symlinks are checked to prevent overwriting frozen reference inputs.

The eight focused default-loop tests run in approximately 0.6 s on the development
machine. The six-hour comparison is deliberately an integration test with a
bounded 180-second test timeout; it is not part of the fast loop.

## Separate root precision, interpolation and propagation

The original sealed external-truth case remains unchanged. Its content and
semantic loader supplies independent Orekit 13.1.7 J2/drag states and access /
cylindrical-eclipse events over 0–21,600 seconds. The new checker calls the actual
`EventSearch.Products.access/2` and `.eclipse/2` production adapters.

First it searches a Hermite interpolant of the frozen Orekit states at two root
tolerances. That removes project propagation as a source of disagreement, while
retaining interpolation error relative to Orekit's continuous event evaluator.
A narrower bracket measures precision on the interpolant, not physical accuracy.

Then it runs project J2Drag at several integration and output cadences. Runtime
physical parameters, actual integration-step provenance, complete output epoch
grids and state counts are checked. Merely labeling a run as a finer cadence
cannot pass. States are compared at all 2,161 common reference epochs. Event
matching checks every expected AOS/LOS and eclipse ingress/egress, together with
the returned numerical root brackets.

A finer independent Orekit RK4 reference was generated with a 2.5-second step
using a byte-identical copy of the original Java generator. Its physical,
time/frame and detector inputs match the original case; exact 10-second state
anchors are retained without interpolation. The original sealed bundle and its
tolerances were not edited. The new source/configuration/filter/output bundle is
content-pinned separately.

| Project source | Independent reference | Max access residual | Max cylindrical eclipse residual |
| --- | --- | --- | --- |
| Orekit anchors, 1 ms root tolerance | Original Orekit 10 s case | 0.2371 ms | 0.2917 ms |
| Orekit anchors, 1 µs root tolerance | Original Orekit 10 s case | 1.350 µs | 1.486 µs |
| Integration/output 10/10 s | Original Orekit 10 s case | 1.350 µs | 1.486 µs |
| Integration/output 5/10 s | New Orekit 2.5 s case | 0.355 µs | 0.567 µs |
| Integration/output 2.5/10 s | New Orekit 2.5 s case | 0.241 µs | 0.339 µs |
| Integration/output 2.5/5 s | New Orekit 2.5 s case | 0.241 µs | 0.275 µs |

Boundary comparison tolerance is 0.001 s for each family. Numerical bracket-width
tolerance is the separately requested root tolerance. State tolerances remain
0.01 m per position component and 1e-5 m/s per velocity component. The largest
position residual in these comparisons is approximately 3.44 mm (project 5 s
against independent 2.5 s). Matched 10 s and 2.5 s runs agree below 1 micrometre
per component; agreement between matched fixed-step methods is not an estimate
of their physical accuracy.

The original 10 s and finer numerical trajectories differ by about 6.39 cm over
six hours. The report retains differences from the original 10 s reference as
**sensitivity only**, without applying its matched-integrator acceptance status
to a different numerical setting. This is why the checker uses an independently
generated finer reference rather than relaxing the old state tolerance or
assuming a finer project run is truth.

The project `eci_j2000` axes are matched to the exact case's EME2000 axes. This
checks no frame transformation or time-system conversion. Atmosphere, constant
Earth rotation, spherical station geometry and fixed-Sun cylindrical shadow are
explicit matched assumptions. These residuals do not cover unrelated force
models, other stations/orbits, EOP, real atmospheric uncertainty or maneuvers.

## Independent finite-Sun reference

`priv/validation/event_search_orekit` contains the generator, pinned dependencies,
inputs, references and content manifest. Regeneration uses pinned Orekit 13.1.7 /
Hipparchus 4.0.3 in a pinned Docker image. Routine checks read only frozen local
bytes. Both reference JSON files reproduced byte-for-byte in a separate directory.

Two synthetic straight flybys cross total and annular shadow. They are geometry
cases, not dynamically feasible spacecraft orbits. Orekit supplies apparent
angular geometry and outer/total contact functions; an angular contact scalar
built from Orekit angles supplies annular internal contacts. Hipparchus Brent
solves the contacts. Expected coverage requires two outer and two inner contacts
per case, with total shadow in one case and annular shadow in the other.

Visible fractions come from numerical vertical-strip integration of overlapping
angular disks, with a variable substitution that smooths square-root endpoints.
The generator does not copy the production analytic lens-area expression. It
imports no project trajectories, event times or lighting results. Expected panel
power uses that independent fraction and Orekit's center-ray cosine.

The checker exercises both the catalog's `Occultations` API and the actual
`SolarArray.evaluate/2` / `.search_boundaries/2` consumer path on the declared
analytic state source. There are 672 frozen sample epochs, including grid points,
contact estimates, both sides of contacts and transition interiors.

| Case | Samples | Maximum visible-fraction difference | Maximum bus-power difference |
| --- | --- | --- | --- |
| Total | 256 | 1.424e-9 | 1.424e-6 W |
| Annular | 416 | 1.721e-9 | 1.721e-6 W |

Fraction tolerance is 1e-8; bus-power tolerance is 1e-5 W for the declared 1 m²,
unit-efficiency panel under 1000 W/m². Apparent-angle tolerance is 1e-10 rad.
Contact-time tolerance is 1e-5 s, with production bracket widths at most 1e-6 s.
The largest catalog contact-time difference is approximately 0.346 µs.

A regime label exactly on a contact can flip with floating-point rounding.
Classification comparison alone is excluded within an explicit 1e-10 rad contact
band (four epochs per case); angle, fraction and power comparisons still apply
at those epochs. Both sides of contacts remain checked.

The fraction model is uniform angular-disk area overlap. Panel power multiplies
that fraction by center-ray cosine. Agreement validates this declared
approximation, not a finite-disk radiance integral, atmosphere, limb darkening,
array hardware or integrated battery-energy error. The finite event scans do not
prove completeness for arbitrary trajectories, narrow events or grazes.

## Verification record

- The full fast-suite run passed 5,247 tests, with 1,144 integration/exhaustive
  checks excluded.
- After the review fixes, all eight focused fast checks passed (one integration
  test excluded), and the explicit six-hour integration test passed in 81.8 s.
  The added control-grid and final-file symlink regressions are included in those
  eight focused checks.
- The final complete CLI report passed with actual sampling-control checks and
  the independently generated finer reference.
- Both frozen reference JSON files reproduced byte-for-byte in a separate
  directory using the pinned generator environment.
- Independent review found and resolved missing actual-cadence checks and
  output-file symlink protection; no remaining blocker was found.
- Formatting and diff whitespace checks passed. Original sealed external-truth,
  mission-baseline and attitude-baseline bundles were unchanged. The full
  integration/exhaustive suites were not run.

The comparison implementation and new evidence remain separate from the
external-truth registry and from general capability validation levels.

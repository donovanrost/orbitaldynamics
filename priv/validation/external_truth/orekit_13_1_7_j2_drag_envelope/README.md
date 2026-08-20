# Orekit 13.1.7 D3 J2-drag envelope corpus

This directory is a content-bound external numerical reference corpus for the
declared Domain 3 J2-plus-drag sample envelope. It contains eight independently
generated Earth/EME2000/TDB fixed-step RK4 cases, each with 25 full-horizon
Cartesian states (200 states total): six combined point-mass/J2/drag cases, one
zero-density J2 case, and one zero-J2 drag case.

The generator uses Apache Orekit 13.1.7 `NumericalPropagator` with Hipparchus
`ClassicalRungeKuttaIntegrator`, automatic Newtonian attraction,
`J2OnlyPerturbation`, `DragForce`, `SimpleExponentialAtmosphere`, and
`IsotropicDrag`. It calls those upstream implementations and never calls or
duplicates the Elixir implementation under test.

The declared sample envelope fixes Earth mu = 398600.4418 km^3/s^2, radius =
6378.1363 km, EME2000, TDB J2000-relative seconds, constant Earth rotation at
7.292115e-5 rad/s, and the simple exponential atmosphere family. Its sampled
bounds are:

- initial altitude 250--800 km, inclination 0--98 degrees, and eccentricity
  0--0.036084741;
- duration 3,600--86,400 s and fixed RK4 step 5--30 s;
- total mass 100--500 kg, area 1--8 m^2, and drag coefficient 2.0--2.4;
- 400 km atmosphere reference altitude, density 0--2e-11 kg/m^3, and scale
  height 50--70 km.

The offline Elixir verifier evaluates every source case through production
`OrbitalDynamics.Propagators.J2Drag` and compares every state at maximum
component tolerances of 0.01 m position and 0.00001 m/s velocity. The corpus
does not promote unsampled continuous combinations, the broader public
arithmetic-safety bounds, other providers, adaptive or accelerated backends,
operational acceptance, or flight certification.

`manifest.json` declares tool/version/container/dependency provenance, units,
case matrix, bounds, tolerances, output counts, and claim boundary.
`case.properties` is the byte-exact multi-case generator input.
`source-manifest.sha256` binds all generator/config/lock/command bytes, and
`reference-output.json` is the raw full-precision Orekit result.

The pinned identities are:

- manifest: `cc086ad9429291abd257b9907cb84b9d71ac0e05accd7cd4dda5c4206e030400`;
- source manifest: `d84b2c94435f61fe0bce7a0f32bd8dcec11c14337ffe02ccb72de4fa32e0cb66`;
- raw result: `5398bf4f44ace3b9928d069b768690aa14fd75a91b7560d22b845689afcddc38`.

## Reproduce

Docker is the only host dependency. The script uses the digest-pinned
`maven:3.9.11-eclipse-temurin-21` Linux/arm64 image, downloads only the
checksum-pinned Orekit/Hipparchus jars into a temporary directory, verifies
them, compiles the generator there, and removes the directory on exit.

From the repository root:

```sh
bundle=priv/validation/external_truth/orekit_13_1_7_j2_drag_envelope
"$bundle/generate.sh" /tmp/orekit-j2-drag-envelope.json
cmp "$bundle/reference-output.json" /tmp/orekit-j2-drag-envelope.json
(cd "$bundle" && shasum -a 256 -c SHA256SUMS)
```

The runtime Elixir verifier is deterministic and offline. Regeneration uses
network access only to retrieve checksum-pinned Maven artifacts.

# Executive Summary

OrbitalDynamics is becoming an auditable mission-planning substrate: Elixir and
the BEAM own orchestration, reproducibility, distribution, artifacts, and
operator-shaped workflow products, while numerical kernels remain explicit,
replaceable, and validation-scoped.

The current project already covers the transparent LEO baseline: Cartesian state
vectors, epochs, frames, central bodies, scalar two-body/J2 propagation, opt-in
provider-backed two-body plus atmospheric-drag propagation, Nx/EXLA experiments,
reproducible study manifests, access windows, target
visibility, eclipses, mission-plan timelines, deterministic search, campaign
planning V1, rolling repair V2, and strategy comparison V3. The remaining work
is not one large rewrite. It is a phased expansion from thin, auditable models
into operationally useful planning products with stronger force models,
resource models, event refinement, optimizer contracts, validation evidence, and
Cadence-facing artifact boundaries.

This document defines the complete feature map for that arc. Status labels mean:

- `implemented`: present in the current repository in a usable form.
- `partial`: present, but intentionally thin or missing important maturity.
- `near-term`: required for the next practical implementation goals.
- `later`: useful for planner maturity after the LEO campaign loop is stable.
- `out of scope`: Cadence-owned, certification-owned, or intentionally outside
  this toolkit boundary.

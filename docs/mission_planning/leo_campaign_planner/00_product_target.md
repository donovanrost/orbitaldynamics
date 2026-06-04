# Product Target

OrbitalDynamics should grow into the planning substrate for a LEO constellation
campaign planner. The planner should turn spacecraft state, mission objectives,
ground-network resources, constraints, and uncertainty into auditable plan
options that Cadence can review, approve, schedule, execute, and compare against
reality.

The goal is not to build every possible astrodynamics model. The goal is to
build a reproducible mission planning runtime with explicit model assumptions,
swappable numerical backends, and operational products that fit naturally into a
ground data system.

In this split:

- `OrbitalDynamics` owns propagation, event detection, search, constraints,
  candidate plan generation, assumptions, and reproducible analysis artifacts.
- Cadence owns operator-facing approval, scheduling, command/contact execution,
  realized operations, and audit trails.

The product arc is:

- V1: Here is a good plan.
- V2: Here is the repaired plan after reality changed.
- V3: Here are the possible futures, here is the recommended strategy, and here
  is why.


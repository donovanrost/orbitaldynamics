# Mission Scope and Coordination

## Mission Phase Modeling

Planning rules change across mission phases. A plan that is acceptable during a
payload campaign may be invalid during commissioning, anomaly recovery, or
disposal.

Mission phases should be explicit in planning inputs and artifacts.

Representative phases:

- integration and test rehearsal
- launch and early orbit
- commissioning
- nominal operations
- payload campaign
- maneuver campaign
- anomaly response
- safe-mode recovery
- degraded operations
- disposal or deorbit
- end-of-life passivation

Each phase can carry:

- allowed activity types
- required authority levels
- model fidelity requirements
- resource reserve policies
- command restrictions
- ground contact requirements
- telemetry confirmation requirements
- special validation evidence
- phase-specific policy bundles

The planner should reject or flag activities that violate the active mission
phase policy.

## Constellation-Level Coordination

High-fidelity planning for a large constellation is not just many independent
spacecraft plans. Fleet-level coordination is a product capability.

Feature areas:

- target assignment across spacecraft
- asset balancing across the fleet
- constellation coverage guarantees
- revisit guarantees
- graceful degradation when spacecraft drop out
- ground-station load balancing
- shared provider calendar contention
- cross-spacecraft fairness policies
- fleet health rollups
- fleet resource rollups
- regional campaign objectives
- priority reallocation after failures
- spare-spacecraft or reserve-capacity strategy

The planner should distinguish per-spacecraft feasibility from fleet-level
mission satisfaction.

## Program and Portfolio Planning

Some organizations operate multiple missions, programs, or customer portfolios
against shared resources.

Feature areas:

- shared ground-network capacity across programs
- shared staffing constraints
- program-level priority arbitration
- budget or cost envelopes
- mission portfolio tradeoffs
- cross-program conflict reporting
- program-specific policy bundles
- customer/program isolation
- executive-level capacity forecasts

OrbitalDynamics should expose portfolio-level conflicts and tradeoffs as
planning artifacts while leaving business authority and program governance to
the host organization.

## Deployment, Phasing, and Fleet Growth

Constellations are not static. Planning should account for launch, deployment,
phasing, replenishment, and retirement.

Feature areas:

- launch batch ingestion
- deployment sequence planning
- commissioning pipeline per spacecraft
- orbit phasing
- drift and rephasing plans
- constellation fill strategy
- spare insertion
- replacement spacecraft planning
- retirement and disposal sequencing
- fleet-growth capacity forecasts
- handoff from commissioning to nominal operations

Deployment and phasing planning connects astrodynamics, mission phase policy,
fleet health, and campaign objectives.

## Operations Procedure Modeling

ICDs describe interfaces and constraints. Operations procedures describe how
operators safely use the spacecraft.

The mature planner should model procedure templates without owning command
execution.

Procedure features:

- procedure identifier and version
- applicable spacecraft/configuration
- preconditions
- go/no-go checks
- hold points
- required telemetry confirmations
- required contact windows
- command sequence references
- rollback or abort steps
- recovery steps
- required authority level
- estimated operator workload
- execution boundary
- post-procedure expected state

Procedure outputs should be review artifacts, not automatic execution products.

## Collaborative Planning

Real mission plans are negotiated across roles.

Representative roles:

- payload planner
- flight dynamics engineer
- ground network scheduler
- mission operations engineer
- customer operations
- systems engineer
- flight director
- spacecraft subsystem engineer

Feature areas:

- proposed deltas by role
- ownership labels
- review status
- comments or rationale references
- conflict ownership
- required reviewer groups
- team-specific approval queues
- role-specific quality gates
- operator-review package partitioning

OrbitalDynamics should preserve collaboration metadata in artifacts without
owning chat, workflow, or approval execution.


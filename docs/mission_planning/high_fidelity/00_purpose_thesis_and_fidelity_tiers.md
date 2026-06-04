# Purpose, Product Thesis, and Fidelity Tiers

## Purpose

This document describes the mature feature target above the current
OrbitalDynamics V1/V2/V3 LEO campaign planner.

The current planner is intentionally transparent and artifact-first. It can
build campaign plans, repair plans, compare strategy branches, refresh
candidates from accepted state, and expose resource summaries. A higher-fidelity
mission planner needs a stronger modeling layer: mission-specific spacecraft and
component models derived from ICDs, subsystem specifications, telemetry
dictionaries, command dictionaries, operational rules, and reference simulators.

The target is not to make OrbitalDynamics own every spacecraft simulator. The
target is to make OrbitalDynamics able to declare, plug in, validate, audit, and
use mission-specific models while keeping Cadence as the operator workflow,
approval, schedule, telemetry, and command-execution boundary.

## Product Thesis

High-fidelity mission planning is not just "better propagation." It is the
ability to answer:

- Is this activity physically and operationally feasible?
- Which subsystem or rule is limiting the plan?
- What resource margins remain after the plan executes?
- Which assumptions and model versions were used?
- What changed between the planned and realized outcome?
- What requires operator review or mission authority approval?

For real missions, engineers typically study ICDs and subsystem documentation,
then encode planning models for the spacecraft bus, payloads, communications,
power, storage, ADCS, propulsion, thermal behavior, command constraints, and
degraded modes. OrbitalDynamics should support that workflow through explicit
model contracts and auditable artifacts.

## Fidelity Tiers

Different missions and planning products need different model depths. The
toolkit should support explicit fidelity tiers rather than pretending every
model is equally trusted.

### Tier 0: External Summary

The planner receives externally supplied margins, flags, and availability
states.

Examples:

- `power_margin`
- `storage_margin`
- `fuel_margin`
- `payload_available`
- `antenna_available`
- `degraded`

This is useful for early planning and operator review, but it does not simulate
subsystem state through time.

### Tier 1: Deterministic Planning Approximation

The planner uses simple fixed-rate assumptions.

Examples:

- fixed bus load in watts
- fixed payload load by activity type
- fixed solar generation when not in eclipse
- fixed data generation rate by observation mode
- fixed downlink throughput by station/contact type
- fixed slew duration or maneuver setup duration

This is suitable for first-pass feasibility and explainable trade studies.

### Tier 2: Time-Stepped Subsystem Projection

The planner propagates subsystem states across the operational timeline.

Examples:

- battery state of charge over sunlight/eclipse intervals
- recorder fill level through observation and downlink activities
- fuel budget through maneuvers
- thermal state through payload duty cycles and eclipse/sun exposure
- antenna availability through contacts and pointing constraints

This is the first tier where the planner can answer "what happens if we run
this plan?"

### Tier 3: Calibrated Mission-Specific Model

The planner uses mission-specific parameters calibrated from telemetry,
operations history, or subsystem analysis.

Examples:

- battery degradation by spacecraft age
- temperature-dependent charge/discharge behavior
- station-specific throughput models
- payload-mode-specific data volume models
- empirically measured activity durations
- spacecraft-specific degraded-mode constraints

This is the tier needed for serious operational confidence.

### Tier 4: Reference or Simulator-Backed Model

The planner calls or compares against external reference tools or
mission-provided simulators.

Examples:

- Orekit, GMAT, STK, Tudat, SPICE
- Basilisk
- vendor power or thermal simulators
- mission-specific link-budget tools
- internal flight-dynamics or operations simulators

OrbitalDynamics should normalize inputs/outputs, preserve provenance, compare
results, and archive validation evidence.


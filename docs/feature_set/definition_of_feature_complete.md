# Definition of Feature Complete

## Library Feature Complete

The library is feature complete when it can run reproducible mission-analysis
studies with explicit units, frames, epochs, force models, environment models,
events, constraints, validation levels, swappable backends, deterministic
artifacts, and documented public APIs. It does not need to be flight-certified
or own operator workflow.

Minimum evidence:

- documented model assumptions and validation level for every output,
- schema-versioned study and result artifacts,
- reference fixtures and tolerances for supported models,
- accepted external planning-state input contract,
- deterministic local and distributed execution behavior,
- backend comparison artifacts for scalar, Nx/EXLA, and any native/external
  adapters.

## LEO Campaign Planning Feature Complete

LEO campaign planning is feature complete when a manifest or mission-state
snapshot for a small constellation can produce a reviewable fixed-horizon plan,
repair that plan after realized operational changes, and compare strategy
branches with explicit tradeoffs.

Minimum evidence:

- propagated spacecraft and generated access, eclipse, and target-visibility
  windows,
- candidate observe, downlink, command, tracking, coast, slew, maneuver, and
  health-check activities,
- station contention, link directionality, throughput estimate, payload and
  resource summaries,
- refreshed candidates from current mission state for rolling replans,
- ranked timelines and plan deltas with explainable score terms,
- warnings, risks, approval requirements, and source-window provenance,
- examples for V1 plan, V2 repair, and V3 strategy artifacts.

## Cadence-Facing Operational Planning Feature Complete

Cadence-facing planning is feature complete when OrbitalDynamics emits stable,
auditable artifacts Cadence can import, review, approve, schedule, execute, and
compare against reality without OrbitalDynamics reaching into Cadence internals.

Minimum evidence:

- proposed contacts with stable IDs, directionality, timing, capacity, and
  station/provider metadata,
- planned activities with dependencies, exclusivity, status, source windows, and
  approval policy,
- maneuver recommendation tables and operational warnings,
- repair deltas and strategy recommendations with reasoned approval boundaries,
- realized feedback input shapes that Cadence can supply after execution,
- schema-validated import/export artifacts and compatibility expectations,
- no direct Cadence database, API, or command-execution dependency.


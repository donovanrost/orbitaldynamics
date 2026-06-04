# Digital Twin and Core Subsystem Models

## Spacecraft Digital Twin Boundary

The mature planner needs a spacecraft model boundary, but not necessarily a
monolithic "digital twin" database.

Feature complete means OrbitalDynamics can represent:

- spacecraft identity and block/build variant
- bus model
- payload model
- flight software version
- command dictionary version
- telemetry dictionary version
- subsystem model versions
- mission phase
- operational mode
- component availability
- model provenance and validation level

The model boundary should be artifact-driven and versioned so a plan can always
answer: "which spacecraft configuration was used to decide this?"

## Configuration Management

Mission planning models are only meaningful if the configuration is explicit.

Required configuration packages:

- spacecraft bus version
- payload version
- flight software version
- ground compatibility version
- command dictionary version
- telemetry dictionary version
- ICD version
- operations-rule bundle
- model-assumptions bundle
- validation-evidence bundle

Planning artifacts should carry configuration references. Compatibility checks
should prevent using a plan model against an incompatible spacecraft, payload,
ground asset, or command dictionary.

## Model Lifecycle

ICD-derived models need lifecycle management.

The mature toolkit should support:

- model draft, review, approved, deprecated, and retired states
- model ownership and review authority
- model effective dates
- compatibility with spacecraft block/build and mission phase
- change history
- validation evidence
- known limits
- replacement model links
- migration notes for artifacts that used older models

This matters because spacecraft behavior changes across vehicles, firmware
versions, payload modes, operating procedures, and mission phases.

## Core Subsystem Models

### Power, Battery, and Solar

A mature power model should represent:

- battery capacity
- state of charge
- minimum operational reserve
- charge and discharge limits
- solar array generation assumptions
- eclipse and sunlight coupling
- bus loads
- payload loads
- communication loads
- heater loads
- activity-mode loads
- battery degradation
- power-safe and power-risky thresholds

Planning outputs should include projected state of charge, minimum margin,
power constraint violations, and assumptions.

### Data Recorder and Storage

A mature storage model should represent:

- recorder capacity
- used storage
- partition or priority classes
- payload data generation rates
- compression assumptions
- housekeeping data generation
- downlink depletion
- deletion rules
- latency requirements
- recorder saturation risk

Planning outputs should include projected storage fill, data latency, downlink
completion, and dropped or deferred data.
Current resource-flow roll-forward keeps this boundary thin and artifact-only:
planned data-volume aliases can drive selected-observation storage production
when explicit storage estimates are absent, while realized data-volume evidence
stays audit-only instead of reconciling recorder state.
`ResourceSummary.capabilities/0` advertises that boundary as a
schema-validated selected-activity projection from `resource_summary.v1` plus
selected activity rows into `resource_projection_flow_summary.v1`; it does not
claim continuous recorder, power, thermal, or link-budget propagation.
Flow summaries keep terminal/rejected/suppressed selected activities visible as
ignored zero-effect rows and expose ignored activity reason counts plus IDs by
ignored-effect reason for review/import routing without reopening the full
projection report. Resource-pressure maps also route station-scoped downlink
pressure by ground station ID, collection/access-window pressure by source
window ID, and provider-calendar pressure by station-calendar entry plus
provider-entry IDs, grouped by pressure type, so queues do not have to reopen
every flow row.
`ResourceProjection.capabilities/0` also advertises the resource source-quality
and trust-boundary alias paths accepted before flow rows derive provenance
routing counts, plus planned and actual data-volume alias paths used by the
storage-production and audit-only evidence boundary. It also names the
estimated/planned downlink-throughput paths consumed before station capacity
adjustment and the declared battery-energy consumed/generated alias paths used
before battery state projection. `resource_projection_report.v1` validation and
schema export now pin the known thin projection model variants so stale model
identifiers fail before the artifact-only resource-state evidence is trusted.

### Communications, Antenna, and Link

A mature communications model should represent:

- antenna availability
- band compatibility
- uplink, downlink, command, and tracking directions
- ground station compatibility
- provider calendar availability
- station reservations
- same-station contention
- link budget assumptions
- data-rate estimates
- weather or provider risk
- command window constraints

Planning outputs should include proposed contacts, contact intent, throughput,
contention status, reservation conflicts, and authority requirements.

### Payload Operations

A mature payload model should represent:

- payload modes
- warm-up and cooldown
- calibration requirements
- duty cycles
- pointing constraints
- target constraints
- data generation
- power and thermal loads
- degraded payload states
- inhibit conditions

Planning outputs should explain why observations are feasible, risky, blocked,
or approval-required.

### ADCS, Pointing, and Slew

A mature ADCS model should represent:

- attitude modes
- slew rates
- settling time
- target pointing constraints
- ground-station pointing constraints
- keep-out zones
- momentum limits
- reaction-wheel or actuator constraints
- safe-mode pointing behavior

Planning outputs should include slew feasibility, setup/settle time, pointing
conflicts, and exclusivity with payload or communications activities.

### Propulsion and Maneuver

A mature propulsion model should represent:

- delta-v budget
- fuel margin
- burn windows
- impulsive and finite burn modes
- maneuver setup and recovery
- pointing constraints
- command authority
- maneuver execution uncertainty
- post-burn OD update expectations
- inhibited propulsion states

Planning outputs should include maneuver feasibility, fuel impact, uncertainty,
approval requirements, and downstream plan risk.

### Thermal

A mature thermal model should represent:

- component temperature states
- heater loads
- sun/eclipse coupling
- payload duty-cycle heating
- safe operating ranges
- cooldown requirements
- hot/cold case assumptions

Planning outputs should include thermal margin, required cooldowns, and thermal
constraint violations.

### Command, FDIR, and Degraded Modes

A mature command and FDIR model should represent:

- commandable states
- command windows
- command authority
- safe mode
- degraded mode
- inhibit flags
- recovery procedures
- health checks
- autonomous safing constraints
- allowed and blocked activities by mode

Planning outputs should distinguish recommendation, operator review, approval,
and execution boundaries.

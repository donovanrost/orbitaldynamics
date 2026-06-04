# Boundaries and Governance

## Cadence Integration Boundary

Cadence should remain the operational system of record.

Expected inputs from Cadence or adjacent systems:

- accepted state snapshots
- spacecraft health and mode state
- resource telemetry summaries
- realized activities
- contact outcomes
- operator-approved constraints
- ground network calendar data
- mission objectives
- policy bundles

Expected outputs to Cadence:

- proposed activities
- proposed contacts
- contact intents
- timeline deltas
- resource projections
- operator review packages
- policy decisions
- approval requirements
- strategy recommendations
- explanation artifacts

Out of scope for OrbitalDynamics:

- Cadence database ownership
- Cadence UI
- command execution
- approval workflow execution
- authoritative telemetry archive
- flight certification

## Planning API Surface

The mature product should document an explicit API surface even if the first
implementation is module-based.

Candidate APIs:

- build campaign
- refresh candidates
- repair plan
- compare strategies
- validate artifact
- export JSON Schema
- run quality gates
- explain candidate rejection
- project resources
- compare plan diffs
- merge plan deltas
- classify policy decisions
- build operator review package
- build Cadence import package
- run simulation/rehearsal
- produce planning observability report

Each API should declare input contracts, output contracts, model assumptions,
validation level, and import/execution boundary.

## Internationalization and Presentation Boundaries

Internal planning artifacts should be machine-stable, while presentation can be
localized or role-specific.

Feature areas:

- UTC-only internal representation
- local station time display metadata
- shift calendar references
- unit presentation rules
- number-format presentation rules
- language/localization boundary for operator text
- role-specific explanation views
- internal code vs display label separation

OrbitalDynamics should emit stable data and presentation hints. Cadence or the
host UI should own localization and display rendering.

## Model Governance

High-fidelity planning models need governance metadata.

Governance fields:

- model owner
- technical reviewer
- approval authority
- validation status
- last calibration date
- applicable spacecraft/configuration
- applicable mission phase
- known invalid regimes
- effective date
- expiration or review date
- superseded-by link
- change rationale
- related ICD/spec/procedure references

Governance should be visible in planning artifacts whenever a model contributes
to feasibility, scoring, risk, or approval decisions.


# Mission Planning

Product-shaped planning documents. These describe what the OrbitalDynamics
mission-planning surface is, what fidelity levels it targets, and how a LEO
constellation campaign planner is structured around the V1/V2/V3 boundaries.

For autonomous implementation loops, start with
[../autonomous_work_guide.md](../autonomous_work_guide.md). Use this directory
after selecting a mission-planning slice.

## Documents

- [moving_resource_validation.md](moving_resource_validation.md) — independent
  moving-wheel and phase-load battery accounting, including checkpoint retries.

- [execution_checkpoints.md](execution_checkpoints.md) — accept execution state
  before planning and retry from an immutable checkpoint after a planning failure.

- [checkpoint_replay.md](checkpoint_replay.md) — preserve saved motion and resource
  history through acquisition, slews, service and terminal-return checkpoints.

- [constellation_assessment.md](constellation_assessment.md) — integrated illumination
  and fixed-attitude missions, repeated operations and assumption sensitivity.

- [thermal_resource.md](thermal_resource.md) — declared heat balance, temperature
  limits, cooldown activities and common-epoch temperature handoff.

- [command_delivery.md](command_delivery.md) — contact prerequisites, shared
  station/spacecraft reservations and explicit delivery receipt history.

- [horizon_extension.md](horizon_extension.md) — finite future coverage, saved
  overlap checks and new demand beyond the original planning horizon.

- [development_queue.md](development_queue.md) — ordered ten-slice queue for
  reference-mission verification, operations behavior and constellation assessment.

- [rigid_body_torque.md](rigid_body_torque.md) — configurable principal inertia and
  body torque capacity, including gyroscopic coupling and transition screening.

- [independent_plan_validation.md](independent_plan_validation.md) — offline checks
  of declared structure, lifecycle and constant-power accounting, with mutation tests.

- [operations_loop.md](operations_loop.md) — deterministic execution/replanning
  cycles, scripted anomalies, lifecycle invariants and one chronological review.

- [rolling_state.md](rolling_state.md) — advance the planning boundary from explicit
  spacecraft state, confirmed completions and remaining resource balances.

- [scheduling_explanations.md](scheduling_explanations.md) — per-request rejection
  evidence, sampled constraints, placement/search limits and rejected trial outcomes.

- [plan_revisions.md](plan_revisions.md) — saved baselines, exact commitments,
  urgent requests, whole-horizon service outages and reviewable revision diffs.

- [protected_replacement.md](protected_replacement.md) — exact activity commitments,
  bounded replacement of tentative work, and quality/runtime comparisons.

- [repeated_service.md](repeated_service.md) — multiple services per asset,
  battery recovery, competing sequences, and independent fixed-time quality cases.

- [scheduling_search.md](scheduling_search.md) — shared feasibility evaluation,
  bounded reassignment, trial limits, and quality/runtime comparison.

- [constellation_benchmark.md](constellation_benchmark.md) — nested synthetic fleets,
  separate planning-stage timings, battery reserves, and exact tiny assignment cases.

- [conservative_opportunities.md](conservative_opportunities.md) — constraint-window
  composition, numerical inside bounds, declared timing margins and scheduling evidence.

- [event_verification.md](event_verification.md) — independent Orekit checks of
  migrated event products, finite-Sun contacts/fractions and solar power.

- [orbital_events.md](orbital_events.md) — bounded standard-event catalog, shared
  source-based search, finite-source contacts, timing and discovery evidence.

- [solar_generation.md](solar_generation.md) — body-mounted panel incidence,
  sampled eclipses, replaceable generation providers and cadence comparisons.

- [resource_feasibility.md](resource_feasibility.md) — complete resource timelines,
  ideal battery energy, charging/loads, reserve gating and unknown coverage.

- [planning_horizon.md](planning_horizon.md) — explicit terminal attitudes and modes,
  terminal acquisition time, idle assets and coverage through the horizon end.

- [verification_baseline.md](verification_baseline.md) — frozen physical cases,
  independent library/ODE comparisons, discrepancies and evidence boundaries.

- [path_constraints.md](path_constraints.md) — sampled activity/transition checks,
  payload modes, reflected-beam exclusion envelopes and path-cadence comparisons.

- [attitude_planning.md](attitude_planning.md) — explicit initial state, full
  pointing profiles and kinematic acquisition/transition checks during scheduling.

- [resolution_studies.md](resolution_studies.md) — independent numerical controls,
  refined transition brackets, sampled margins and schedule stability reports.

- [trade_studies.md](trade_studies.md) — configurable parameter sweeps, compact
  comparison reports and an independently checked reference baseline.

- [reference_missions.md](reference_missions.md) — runnable configurable illumination
  and imaging examples using the opt-in mission-independent analysis API.

- [leo_campaign_planner/](leo_campaign_planner/README.md) — the LEO
  constellation campaign planner spec. V1 campaign plan generation, V2
  rolling operations planner, V3 mission orchestration, implementation
  implications, and the near-term product slice.
- [high_fidelity/](high_fidelity/README.md) — the high-fidelity
  mission-planning feature set. Fidelity tiers, digital-twin and subsystem
  models, planning lifecycle, constraints/objectives, operational concerns,
  validation, and the maturity matrix.
- [toolkit_spec.md](toolkit_spec.md) — the original mission planning
  toolkit spec. Project thesis, capability levels, domain model,
  behaviour contracts, accuracy policy, backend plan, first useful slice,
  distribution thesis, non-goals, and near-term plan.

- [reaction_wheels.md](reaction_wheels.md) — signed rotor momentum, motor torque,
  costed external unloading and state continuity through replanning.

- [automatic_maintenance.md](automatic_maintenance.md) — bounded joint maintenance
  and service scheduling, automatic unloading choices and execution continuity.

- [maintenance_work_observation.json](maintenance_work_observation.json) — whole-search
  callback accounting and deterministic shared-budget stops on one/two spacecraft.

- [interval_availability.md](interval_availability.md) — activity/mode outages,
  exact restoration boundaries, protected conflicts and independent checks.

- [state_quality.md](state_quality.md) — offline observation provenance, freshness,
  validity and declared-error gates before advancing a planning boundary.

- [in_progress_activities.md](in_progress_activities.md) — original-profile
  continuations, executed prefixes, single-charge costs and completion lineage.

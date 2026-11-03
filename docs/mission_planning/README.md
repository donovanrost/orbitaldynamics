# Mission Planning

Product-shaped planning documents. These describe what the OrbitalDynamics
mission-planning surface is, what fidelity levels it targets, and how a LEO
constellation campaign planner is structured around the V1/V2/V3 boundaries.

For autonomous implementation loops, start with
[../autonomous_work_guide.md](../autonomous_work_guide.md). Use this directory
after selecting a mission-planning slice.

## Documents

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

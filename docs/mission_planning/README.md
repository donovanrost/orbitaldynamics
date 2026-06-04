# Mission Planning

Product-shaped planning documents. These describe what the OrbitalDynamics
mission-planning surface is, what fidelity levels it targets, and how a LEO
constellation campaign planner is structured around the V1/V2/V3 boundaries.

For autonomous implementation loops, start with
[../autonomous_work_guide.md](../autonomous_work_guide.md). Use this directory
after selecting a mission-planning slice.

## Documents

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

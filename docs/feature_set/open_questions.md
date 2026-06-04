# Open Questions

- What is the minimum Cadence import schema for proposed contacts and planned
  activities?
- What is the accepted planning-state contract for updated spacecraft states,
  covariance, maneuver execution deltas, and source quality metadata?
- Which interchange format should be supported first: TLE/SGP4, CCSDS OMM,
  OEM, OPM, CDM, or a simpler CSV/JSON adapter?
- Should operational activity structs live under `MissionPlan`, `CampaignPlanner`,
  or a new timeline namespace?
- Which reference tool should become the first validation baseline: SPICE,
  Orekit, GMAT, Tudat, or curated analytical fixtures?
- How formal should JSON Schema generation become before artifacts stabilize?
- What resource model is sufficient for the next useful LEO planner: static
  summaries, simple state transitions, or subsystem-specific simulators?
- How should branch probabilities be represented when they are planning
  assumptions rather than measured probabilities?
- When should `Nx` become conditional, and how should backend modules compile
  when optional dependencies are absent?
- Which event detector should be refined first: AOS/LOS, eclipse, target
  visibility, or maneuver-related events?
- What ID stability guarantees do Cadence-facing artifacts need across replans?
- How much distributed execution state is needed before resumable studies become
  necessary?
- How should the current V1/V2/V3 scale targets evolve once benchmark reports
  include longer distributed runs and larger campaign-planning artifacts?
- Which policy decisions belong in OrbitalDynamics artifacts versus Cadence's
  approval workflow?
- How strict should external-input trust controls be for manifests,
  ephemerides, and backend/service providers?


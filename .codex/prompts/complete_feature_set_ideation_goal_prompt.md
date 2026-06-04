# `/goal` Prompt: Complete Feature Set Ideation

```text
Ideate and document the complete feature set for the OrbitalDynamics project.

Context:
- OrbitalDynamics is an Elixir orbital/astrodynamics and mission-planning toolkit.
- The broader product target is to become the planning substrate for Cadence, a ground data system for large-constellation spacecraft operations.
- Existing docs include:
  - `docs/mission_planning_toolkit_spec.md`
  - `docs/leo_constellation_campaign_planner.md`
- Existing implemented directions include propagation, studies, access windows, eclipses, target visibility, mission plans, campaign planning V1, V2 repair, and V3 strategy evaluation.

Goal:
Produce a complete, structured feature-set map for the project. The output should help decide what “feature complete” means across the whole toolkit and how to phase the work from current capabilities to a mature mission planning platform.

Important:
- This is an ideation/documentation goal, not an implementation goal.
- Read the current code and docs first.
- Ground the feature map in what already exists.
- Identify missing features without pretending everything must be built immediately.
- Keep Cadence integration as a product boundary, not something to implement in this goal.

Done means:
- Create a new documentation file under `docs/` that describes the complete feature set.
- The doc should distinguish:
  - already implemented,
  - near-term required,
  - medium-term planner maturity,
  - long-term advanced capability,
  - explicitly out of scope.
- The doc should organize features by capability area, not just by version number.
- The doc should include a recommended phased roadmap.
- The doc should include a “definition of feature complete” for several useful maturity levels.
- The doc should include risks, assumptions, and open questions.
- Update README or existing docs only if a short pointer is useful.
- Do not make code changes unless a tiny doc-link update is necessary.

Feature areas to cover:

1. Core astrodynamics foundations
- State vectors, epochs, time scales, reference frames, central bodies.
- Orbital elements and conversions.
- Frame transforms.
- Time-system handling.
- Earth orientation assumptions.
- Units and validation policy.
- Numerical accuracy levels.

2. Propagation and force models
- Two-body propagation.
- J2 and higher-order gravity.
- Drag models and atmosphere interfaces.
- Solar radiation pressure.
- Third-body perturbations.
- Finite burns and impulsive burns.
- Maneuver execution uncertainty.
- Adaptive integration and event refinement.
- Backend contracts for scalar Elixir, Nx/EXLA, NIFs, external tools, or services.

3. Environment and ephemeris providers
- Earth, Sun, Moon, planets.
- Solar vector/source models.
- Earth-fixed and inertial environment models.
- SPICE/Orekit/GMAT/Tudat adapter possibilities.
- External ephemeris provider interfaces.
- Validation evidence and model capability declarations.

4. Event detection
- Ground-station access windows.
- Target visibility windows.
- Eclipse intervals.
- AOS/LOS refinement.
- Elevation masks and terrain/horizon masks.
- Lighting conditions.
- Latitude/longitude crossings.
- Apsides, node crossings, conjunction/collision screening.
- Event confidence and timing tolerances.

5. Spacecraft and payload modeling
- Spacecraft identity and metadata.
- Mass, drag area, SRP area, ballistic coefficient.
- Propellant/fuel summaries.
- Power and battery summaries.
- Storage/data-volume summaries.
- Payload availability, pointing constraints, duty cycles.
- Antenna/link availability.
- Degraded modes and spacecraft health constraints.

6. Ground network and communications planning
- Ground stations and provider networks.
- Link directionality: downlink, uplink/command, tracking.
- Contact windows and contact intents.
- Link capacity and throughput estimates.
- Station outages and capacity reductions.
- Schedule conflicts and resource contention.
- Output artifacts suitable for Cadence scheduled contacts.

7. Mission activities and timelines
- Observe, downlink, command, tracking, slew, coast, maneuver, health check.
- Activity dependencies.
- Activity exclusivity and overlap rules.
- Locked/approved/executed activity preservation.
- Timeline products and operator review artifacts.
- Activity provenance and source windows.

8. Constraints and scoring
- Deterministic pass/fail/warning constraints.
- Scored objectives.
- Priority commitments.
- Coverage and revisit goals.
- Downlink completion and latency.
- Fuel preservation.
- Schedule churn.
- Asset balancing.
- Risk scoring.
- Approval burden.
- Explainable score terms.

9. Search and optimization
- Grid search.
- Monte Carlo search.
- Candidate activity generation.
- Timeline selection.
- Greedy repair.
- Multi-objective ranking.
- Branch/what-if comparison.
- Future optimizers: local search, MILP/CP-SAT, stochastic search, evolutionary methods, dynamic programming, or external optimizer adapters.
- Reproducibility and seed manifests.

10. V1 campaign planning
- Fixed-horizon campaign planning.
- Multiple spacecraft.
- Targets, ground stations, constraints, scoring policy.
- Candidate activities.
- Ranked timelines.
- Proposed contacts.
- Plan artifacts suitable for operator review.

11. V2 rolling repair
- Prior plan plus realized state.
- Missed/failed/delayed/canceled/partial operations.
- Repaired remaining horizon.
- Plan deltas.
- Schedule churn costs.
- Preservation policy.
- Approval requirements.
- Degraded spacecraft handling.

12. V3 strategy/orchestration
- Mission-state snapshots.
- Derived branches.
- Explicit what-if branches.
- Strategy recommendation.
- Resource summaries.
- Operational feedback.
- Action-specific approval policy.
- Urgent target feasibility.
- Structured recommendation explanation.
- Remaining gaps such as refreshed candidate generation, combined futures, and robust strategy selection.

13. Future V4+ possibilities
- Mission-state-to-candidate refresh.
- Persistent digital twin integration.
- Robust planning across multiple simultaneous futures.
- Resource allocation across fleet-level constraints.
- Plan simulation and branch trees.
- Learned/calibrated operational models.
- Cross-regime support: MEO, GEO, cislunar, interplanetary.
- Formation flying or deployment campaign planning.
- Autonomous planning with strict approval boundaries.

14. Reproducibility, artifacts, and audit
- Study manifests.
- Result sets.
- Plan artifacts.
- Repair artifacts.
- Strategy artifacts.
- Assumptions, provenance, model limits, generated IDs.
- JSON schema/versioning considerations.
- Deterministic ordering.
- Report generation.

15. Validation and verification
- Analytical checks.
- Conserved quantities.
- Reference-tool comparisons.
- Event timing tolerances.
- Regression fixtures.
- Benchmark artifacts.
- Backend comparisons.
- Model validation levels: educational, analysis, validated.

16. Performance and distribution
- Local concurrency.
- Distributed BEAM execution.
- Batch propagation.
- Nx/EXLA acceleration.
- Native backend options.
- Transfer overhead and result payload costs.
- Resumable studies.
- Failure isolation.

17. Cadence boundary and integration artifacts
- What OrbitalDynamics should emit.
- What Cadence should own.
- Proposed contacts.
- Planned activities.
- Approval requirements.
- Warnings and risk explanations.
- Realized operations feedback shape.
- No direct Cadence database/API implementation in this ideation goal.

18. Developer and user experience
- Public APIs.
- JSON manifests.
- Examples and demos.
- Reports.
- Documentation.
- Error messages.
- Stable artifact schemas.
- Package/dependency strategy, especially optional numerical backends.

Expected output file:
- Create `docs/complete_feature_set.md`.

Suggested structure for `docs/complete_feature_set.md`:

1. Executive Summary
2. Product Thesis
3. Current Capability Snapshot
4. Feature Completeness Levels
   - Level 0: Transparent astrodynamics baseline
   - Level 1: Reproducible studies
   - Level 2: Useful LEO analysis
   - Level 3: Campaign planner V1
   - Level 4: Rolling operations planner V2
   - Level 5: Strategy/orchestration planner V3
   - Level 6: Mature operational planning platform
5. Capability Map
   - One section per feature area listed above
   - For each capability, label status as:
     - implemented
     - partial
     - near-term
     - later
     - out of scope
6. Recommended Roadmap
   - next 1-2 implementation goals
   - next 3-5 implementation goals
   - long-term goals
7. Definition of Feature Complete
   - for the library
   - for LEO campaign planning
   - for Cadence-facing operational planning
8. Major Risks and Design Principles
9. Open Questions
10. Appendix: Candidate Artifact Types and APIs

Quality bar:
- Be concrete and product-shaped.
- Do not write generic aerospace wishlists detached from this repo.
- Use the actual module names and artifacts that exist where relevant.
- Clearly separate mission-analysis capability from operational-product capability.
- Clearly separate thin current models from future high-fidelity models.
- Preserve the project principle that assumptions must be explicit and auditable.
- Favor phased maturity over trying to build everything at once.

Verification:
- Since this is documentation-only, no full test run is required unless code changes are made.
- If README or other docs are edited, check links and formatting by reading the changed sections.

Suggested first step:
Read `README.md`, `docs/mission_planning_toolkit_spec.md`, `docs/leo_constellation_campaign_planner.md`, and the main modules under `lib/orbital_dynamics/`. Then draft `docs/complete_feature_set.md` from the actual repo state.
```

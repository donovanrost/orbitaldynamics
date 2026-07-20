# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OrbitData accepted-planning-state construction extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract accepted-planning-state artifact construction, state-estimate
normalization, epoch/vector/quality validation, maneuver-execution-delta
normalization, and inherited provenance into
`OrbitalDynamics.OrbitData.AcceptedPlanningState`.
Preserve all OrbitData and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `orbit_data.ex` at 1,856 lines, the
  largest ordinary eligible facade.
- OrbitData delegates TLE and OMM metadata inspection, while accepted planning
  state construction remains inline at lines 1,540-1,765.
- The selected block has one responsibility: normalize validated state and
  maneuver-delta inputs into the accepted planning-state artifact contract.
- JSON/OPM/OEM adapter routing, KVN parsing/export, schema validation, common
  adapter provenance helpers, and all public contracts remain outside the
  boundary.
- Exact validation precedence and errors, index paths, epoch/vector shape,
  provenance inheritance, delta normalization, omission behavior, artifact
  output, and bang/non-bang facade behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext timeline-activity-precondition extraction, selected
in `d27a1946` and implemented in `9201d18b`.
`recommendation_risk_context.ex` moved from 1,893 to 1,772 lines; the dedicated
TimelineActivityPrecondition owner is 158 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `orbit_data.ex` is now the largest ordinary eligible facade at
1,856 lines, followed by StationCalendar and ContactAllocation.

Blocked:
No.

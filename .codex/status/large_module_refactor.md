# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OrbitData accepted-planning-state construction extraction.

Status:
Completed and pushed in `fe2b4773`.

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
- Added `OrbitalDynamics.OrbitData.AcceptedPlanningState` as the owner of
  artifact construction, state-estimate normalization, epoch/vector/quality
  validation, maneuver-execution-delta normalization, and inherited
  provenance.
- Preserved OrbitData and root public APIs; the facade retains narrow
  construction and maneuver-delta delegates used by JSON/OPM/OEM adapters.
- Removed accepted-state-specific validation and normalization helpers from the
  facade while leaving shared adapter/schema helpers in place.
- `orbit_data.ex` moved from 1,856 to 1,596 lines; the new owner is 303 lines.

Verification:
- Strict focused baseline passed all 37 OrbitData tests.
- Exact old/new public parity passed for five deterministic results: a
  successful multi-state artifact with inherited provenance and maneuver
  delta, empty estimates, invalid vector, missing snapshot ID, and invalid
  maneuver delta.
- Post-extraction focused and adjacent accepted-state schema verification
  passed all 43 tests.
- Static checks confirm accepted-state implementation helpers left the facade;
  xref reports only OrbitData as a runtime caller.
- Strict warning-clean forced compile passed for 4,005 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
OrbitData accepted-planning-state construction extraction, selected in
`036ac21a` and implemented in `fe2b4773`.
`orbit_data.ex` moved from 1,856 to 1,596 lines; the dedicated
AcceptedPlanningState owner is 303 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `communications/station_calendar.ex` is now the largest ordinary
eligible facade at 1,814 lines, followed by ContactAllocation and
TimelineFeedback.

Blocked:
No.

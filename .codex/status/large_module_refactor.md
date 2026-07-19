# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Manifest candidate-refresh accepted planning-state extraction.

Status:
Completed and pushed in `24f39a5c`.

Selected boundary:
Extract accepted-planning-state selection, schema validation, mission-state
fallback construction, spacecraft-state completion, and orbit-data import
fallback into
`OrbitalDynamics.Study.Manifest.CandidateRefreshPlanningState`.
Preserve the existing Manifest public API facade.

Selection evidence:
- Live re-ranking places `manifest.ex` at 3,638 lines, fourth behind Schema,
  Timeline, and MissionPlan.Activity and ahead of ResourceProjection,
  TimelineFeedback, ContactAllocation, RecommendationRiskContext,
  OrbitalDynamics, LinkCapacity, and StationCalendar.
- The selected family owns one candidate-refresh input responsibility reused
  by simulator and artifact-only manifest paths: resolving the authoritative
  accepted planning state from explicit, mission-state, or orbit-data inputs.
- Horizon, target/ground-station discovery, policies, activities, run options,
  schema generation, and manifest assembly remain outside this boundary.
- Existing source precedence, schema validation, mission-state defaults,
  identity completion, orbit-data errors, and missing/invalid classifications
  remain unchanged.

Verification:
- Strict test-environment compile passed with warnings as errors across 3,921
  files.
- Focused Manifest coverage passed: 42 tests.
- Adjacent manifest-fixture validation coverage passed: 2 tests.
- Exact public old/new comparison against selection commit `a1394b10` passed
  for eight normalized `from_map/1` samples covering explicit accepted state,
  mission-state construction/defaults, orbit-data import, and five
  invalid/missing cases.
- `mix xref callers` reports only the Manifest facade as a runtime caller of
  the extracted planning-state owner.
- Static ownership checks confirm planning-state precedence, validation,
  mission-state completion, and orbit-data fallback live in the dedicated
  owner while horizon and manifest responsibilities remain in the facade.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Manifest candidate-refresh accepted planning-state extraction, selected in
`a1394b10` and implemented in `24f39a5c`.
`manifest.ex` moved from 3,638 to 3,530 lines; the dedicated planning-state
owner is 109 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.

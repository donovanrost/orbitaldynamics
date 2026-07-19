# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Manifest candidate-refresh run-input source extraction.

Status:
Completed and pushed in `74cc1a1d`.

Selected boundary:
Extract candidate-refresh accepted-state, target, and ground-station run-input
source discovery across explicit inputs, mission-state catalogs/objectives,
ground-network geometry, and orbit data into
`OrbitalDynamics.Study.Manifest.CandidateRefreshRunInputSources`.
Preserve the existing Manifest public API facade.

Selection evidence:
- Live re-ranking places `manifest.ex` at 3,530 lines, fourth behind Schema,
  Timeline, and MissionPlan.Activity and ahead of LinkCapacity,
  StationCalendar, TimelineFeedback, ResourceProjection, ContactAllocation,
  RecommendationRiskContext, and OperationalReadiness.
- The selected family owns one provenance responsibility used by
  candidate-refresh manifest metadata: declaring which accepted-state,
  target, and ground-station inputs were actually present.
- Candidate-refresh planning-state resolution, target/ground-station parsing,
  scenario construction, policies, activities, schema generation, and manifest
  assembly remain outside this boundary.
- Existing source vocabulary and ordering, geometry-presence rules,
  explicit-versus-mission-state inclusion behavior, empty-list handling, and
  deterministic output remain unchanged.

Verification:
- Strict test-environment compile passed with warnings as errors across 3,927
  files.
- Focused Manifest coverage passed: 42 tests.
- Adjacent candidate-refresh operator-review and schema-contract coverage
  passed: 12 tests.
- Exact public old/new comparison against selection commit `a29d7dd7` passed
  for four `from_map/1` states covering explicit inputs, mission-state
  catalogs, objective/ground-network geometry aliases, and mixed explicit plus
  mission-state sources.
- `mix xref callers` reports only the Manifest facade as a runtime caller of
  the extracted run-input-source owner.
- Static ownership checks confirm accepted-state, target, and ground-station
  source vocabulary, geometry presence, and objective target-alias expansion
  live in the dedicated owner while parsing and manifest assembly remain in the
  facade.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Manifest candidate-refresh run-input source extraction, selected in `a29d7dd7`
and implemented in `74cc1a1d`.
`manifest.ex` moved from 3,530 to 3,357 lines; the dedicated run-input-source
owner is 185 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
State/maneuver fixture mapping.

Status:
Publishing.

Selected slice:
Move
`spacecraft_state_estimate.v1`, `realized_state_snapshot.v1`,
`remaining_horizon.v1`, `maneuver_execution_delta.v1`, and
`maneuver_recommendation.v1` into a new
`Validation.ReferenceFixtures.StateManeuverArtifacts` leaf. Stop before
`backend_acceptance_policy.v1`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 7,826 lines. The
next five contiguous fixtures form a 208-line state/maneuver family that
exactly owns `state_maneuver_fixture_test.exs`.

Current coupling/problem:
State estimates, realized snapshots, remaining horizon, maneuver delta, and
recommendation remain embedded together in the general facade. Their shared
state-to-maneuver responsibility and focused test justify one cohesive leaf.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.StateManeuverArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/state_maneuver_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused state/maneuver and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The five state/maneuver fixtures exist only in the new cohesive leaf, all 27
fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the same
195-entry map and deterministic term bytes, `backend_acceptance_policy.v1` and
the complete facade remainder stay exact, focused and full validation tests
pass, and bounded review finds no blocker.

Verification gaps:
- None for this bounded slice.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected five-fixture map: deterministic digest
  `99b626d31505e6bdcb901988e0afef9eedc57ffe1130e66bf45bc51f93353245`.
- Exact 190-entry remainder: deterministic digest
  `9b3276e07ff9c2a2268fe6202430e964cbeaa8ce372dad9261a721c527c15e49`.
- Source boundary confirmed at facade lines 159-366, with
  `backend_acceptance_policy.v1` beginning at line 367 and no facade
  helper-attribute dependency in the selected literals.
- Post-move exact proof: the 195-entry map, sorted-key digest, selected
  five-fixture digest, and exact 190-entry remainder digest all match their
  selection baselines.
- Source partition proof: 27 maps total 195 entries, the new leaf owns five, the
  facade owns 102, and all 351 pairwise intersections are empty.
- Facade proof: all 195 successful `fetch/1` results, missing-key `:error`, and
  nonbinary `FunctionClauseError` behavior remain unchanged.
- Focused state/maneuver/facade validation: 17 tests passed.
- Full validation family: 181 tests passed.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review: CLEAN. It confirmed all five state/maneuver
  fixtures moved unchanged, the backend-policy boundary and complete facade
  remainder are normalized-AST exact, the new leaf owns only its five intended
  keys, all 27 maps are unique and pairwise disjoint, all digests and facade
  edge behaviors are unchanged, dependencies remain one-way, and it reproduced
  17 focused and 181 full validation tests.

Behavior/schema changes:
None.

Outcome:
The exact five-fixture state/maneuver family now lives in a new cohesive leaf
behind the unchanged facade. The facade shrank from 7,826 to 7,620 lines; the
new leaf is 216 lines and owns exactly five fixtures.

Last completed slice:
Refreshed-window lineage extraction published as `ffabc35d`: the exact pair
moved into a new 88-line leaf, the facade shrank from 7,904 to 7,826 lines, the
195-entry map and all deterministic digests stayed exact, 16 focused and 181
full validation tests passed, and bounded review was clean.

Next candidate:
Select the state/maneuver extraction described above, capture the exact
baseline and source boundary, then stop before
`backend_acceptance_policy.v1`.

Blocked:
No.

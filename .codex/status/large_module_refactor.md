# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
State/maneuver fixture mapping.

Status:
Ready for next slice selection.

Selected slice:
No implementation selected yet. The next bounded candidate is to move
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
- Next candidate still requires a selection baseline before implementation.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected two-fixture map: deterministic digest
  `9871471bbf9a63cf018b9d9b5a008a432df478756f4f2b52ce3e7c534435a669`.
- Exact 193-entry remainder: deterministic digest
  `402653897f9a6052f1460f8a60bd153f99fe3e64453b293b4332a22898b407c1`.
- Source boundary confirmed at facade lines 158-237, with
  `spacecraft_state_estimate.v1` beginning at line 238 and no facade
  helper-attribute dependency in the selected literals.
- Post-move exact proof: the 195-entry map, sorted-key digest, selected
  two-fixture digest, and exact 193-entry remainder digest all match their
  selection baselines.
- Source partition proof: 26 maps total 195 entries, the new leaf owns two, the
  facade owns 107, and all 325 pairwise intersections are empty.
- Facade proof: all 195 successful `fetch/1` results, missing-key `:error`, and
  nonbinary `FunctionClauseError` behavior remain unchanged.
- Focused contact-window/facade validation: 16 tests passed.
- Full validation family: 181 tests passed.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review: CLEAN. It confirmed both refreshed-window
  fixtures moved unchanged, the spacecraft-state boundary and complete facade
  remainder are normalized-AST exact, the new leaf owns only its two intended
  keys, all 26 maps are unique and pairwise disjoint, all digests and facade
  edge behaviors are unchanged, dependencies remain one-way, intent/state
  ownership remains distinct, and it reproduced 16 focused and 181 full
  validation tests.

Behavior/schema changes:
None.

Outcome:
No state/maneuver implementation has started.

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

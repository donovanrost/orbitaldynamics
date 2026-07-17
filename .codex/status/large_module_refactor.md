# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Accepted-planning-state reference-fixture family extraction.

Status:
Ready for implementation.

Selected slice:
Move the first three contiguous artifact fixtures—accepted planning state
`simple`, `opm`, and `oem`—into
`Validation.ReferenceFixtures.AcceptedPlanningState`. Merge that family with
the existing orbital family and remaining facade map behind unchanged
`ReferenceFixtures.all/0` and `fetch/1`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 13,142 lines.
These three fixtures are its first remaining block, share the single
`artifact.accepted_planning_state.v1` contract, and have dedicated focused
coverage in `validation/candidate_state_fixture_test.exs`.

Current coupling/problem:
Three independent literal fixture values remain embedded in the facade even
though they form one contract family. The 137-line block references no facade
helper attributes, so it can move mechanically without pulling unrelated
candidate-refresh fixture construction with it.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.AcceptedPlanningState`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/accepted_planning_state.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused candidate-state fixture and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The three fixtures exist only in the accepted-planning-state family module, all
three fixture families have disjoint key sets, `all/0` and `fetch/1` return
exactly the same 195-entry map and deterministic term bytes, focused and full
validation tests pass, and bounded review finds no blocker.

Verification gaps:
- Implementation and verification pending.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selection only; implementation verification pending.

Behavior/schema changes:
None.

Last completed slice:
Validation orbital/event reference-fixture extraction published as `005cbbc4`:
the six exact fixtures moved behind the unchanged facade, the 195-entry map and
deterministic bytes stayed exact, 181 validation tests passed, and bounded
review was clean.

Next candidate:
After this boundary, remap the next contiguous artifact family and its focused
tests before selecting another move; do not treat the large candidate-refresh
fixture range as one slice.

Blocked:
No.

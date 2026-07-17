# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-state report reference-fixture extraction.

Status:
Ready for implementation.

Selected slice:
Move the contiguous `candidate_rejection_report.v1` and
`candidate_diff_row.v1` fixtures into
`Validation.ReferenceFixtures.CandidateStateArtifacts`. Stop before the
environment-capability block and merge the new family behind unchanged
`ReferenceFixtures.all/0` and `fetch/1`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 10,424 lines.
These two fixtures form one contiguous 108-line candidate-state report family
and have one dedicated focused owner in
`validation/candidate_state_fixture_test.exs`.

Current coupling/problem:
Two related checked-in candidate report fixtures remain embedded in the facade
despite shared candidate-state responsibility and test ownership. Neither
references a facade helper attribute, so the pair can move without coupling
the following environment-capability family.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.CandidateStateArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/candidate_state_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused candidate-state and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The two report fixtures exist only in the candidate-state family module, all 15
fixture maps have disjoint key sets, `all/0` and `fetch/1` return exactly the
same 195-entry map and deterministic term bytes, focused and full validation
tests pass, and bounded review finds no blocker.

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
Candidate-refresh capacity/filter fixture extraction published as `bd39ca7f`:
the final two replay fixtures moved behind the unchanged facade, the first
non-candidate-refresh report and remainder stayed exact, the 195-entry map and
deterministic bytes stayed exact, 181 validation tests passed, and bounded
review was clean.

Next candidate:
After this boundary, extract the six contiguous environment model/provider
capability fixtures if their runtime-derived observations remain entirely
outside the literal map and focused planning-input coverage proves the family.

Blocked:
No.

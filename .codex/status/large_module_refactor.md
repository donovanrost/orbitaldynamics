# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-state report reference-fixture extraction.

Status:
Completed and published as `089ee63a`.

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
- None for this bounded slice.

Tests run:
- Exact post-split proof matched the 195-entry selection baseline,
  deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Source-boundary proof found 2 candidate-state, 2 capacity/filter, 2
  filter/rejection, 2 planning-feedback, 4 timeline, 3 readiness, 2 contact, 2
  station-allocation, 2 freshness/budget, 2 base, 3 campaign-planning, 10
  campaign-artifact, 3 accepted-state, 6 orbital, and 150 facade keys with no
  duplicate anchors; facade `fetch/1` matched both moved values.
- Strict test compile passed with warnings as errors.
- Focused candidate-state, core-policy, and facade validation tests: 17 passed.
- Full validation test family: 181 passed.
- Format, tracked/untracked diff hygiene, and xref caller checks passed.
- Bounded read-only review was clean: exactly baseline indices 1-2 moved, the
  environment-capability block and full remainder stayed exact, all 15 maps
  are pairwise disjoint, their union equals `27841ffb`, fetch edge behavior
  matches, and compile dependencies are one-way.

Behavior/schema changes:
None.

Outcome:
The candidate-rejection-report and candidate-diff-row fixtures now live in
`Validation.ReferenceFixtures.CandidateStateArtifacts`; the facade merges that
family with 14 existing fixture maps plus 150 remaining fixtures. The facade
fell from 10,424 to 10,318 lines, while the extracted family is 116 lines.

Last completed slice:
Candidate-state report fixture extraction published as `089ee63a`: the two
exact report/diff fixtures moved behind the unchanged facade, the environment-
capability block and remainder stayed exact, the 195-entry map and deterministic
bytes stayed exact, 181 validation tests passed, and bounded review was clean.

Next candidate:
Extract the six contiguous environment model/provider capability fixtures into
one family. The 255-line block has no helper-attribute coupling, its runtime
observation construction remains outside the literal map, it shares focused
`planning_input_fixture_test.exs` coverage, and it stops before
`branch_comparison_report`; re-baseline before selecting.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-strategy reference-fixture extraction.

Status:
Completed and published as `6e55724f`.

Selected slice:
Move the contiguous branch-comparison, optimizer-contract, and
invalidated-candidate fixtures into
`Validation.ReferenceFixtures.CandidateStrategyArtifacts`. Stop before
`candidate_diff_report.v1` and merge the new family behind unchanged
`ReferenceFixtures.all/0` and `fetch/1`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 10,065 lines.
These three fixtures form one contiguous 233-line candidate-strategy family,
and every key has focused coverage in
`validation/candidate_strategy_fixture_test.exs`.

Current coupling/problem:
Three related strategy/decision fixtures remain embedded in the facade despite
shared candidate-strategy responsibility and focused test ownership. None
references a facade helper attribute, so they can move without coupling the
following core-run report family.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.CandidateStrategyArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/candidate_strategy_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused candidate-strategy and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The three strategy fixtures exist only in the candidate-strategy family, all 17
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
- Source-boundary proof found 3 candidate-strategy, 6 environment, 2
  candidate-state, 2 capacity/filter, 2 filter/rejection, 2 planning-feedback,
  4 timeline, 3 readiness, 2 contact, 2 station-allocation, 2
  freshness/budget, 2 base, 3 campaign-planning, 10 campaign-artifact, 3
  accepted-state, 6 orbital, and 141 facade keys with no duplicate anchors;
  facade `fetch/1` matched all three moved values.
- Strict test compile passed with warnings as errors.
- Focused candidate-strategy, core-policy, and facade validation tests: 18
  passed.
- Full validation test family: 181 passed.
- Format, tracked/untracked diff hygiene, and xref caller checks passed.
- Bounded read-only review was clean: exactly baseline indices 1-3 moved,
  candidate diff and the full remainder stayed exact, all 17 maps are pairwise
  disjoint, their union equals `0e2727af`, fetch edge behavior matches, and
  compile dependencies are one-way.

Behavior/schema changes:
None.

Outcome:
The branch-comparison, optimizer-contract, and invalidated-candidate fixtures
now live in `Validation.ReferenceFixtures.CandidateStrategyArtifacts`; the
facade merges that family with 16 existing fixture maps plus 141 remaining
fixtures. The facade fell from 10,065 to 9,834 lines, while the extracted
family is 241 lines.

Last completed slice:
Candidate-strategy fixture extraction published as `6e55724f`: the three exact
branch/optimizer/invalidation fixtures moved behind the unchanged facade,
candidate diff and the remainder stayed exact, the 195-entry map and
deterministic bytes stayed exact, 181 validation tests passed, and bounded
review was clean.

Next candidate:
Extract the four contiguous candidate-diff, refresh-budget, execution, and
freshness report fixtures into a core-run-report family. The 243-line block
shares dedicated `core_run_report_fixture_test.exs` ownership and stops before
manifest-field-reference; first verify helper-attribute independence and
re-baseline the complete map.

Blocked:
No.

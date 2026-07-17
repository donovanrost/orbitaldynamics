# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-strategy reference-fixture extraction.

Status:
Ready for implementation.

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
Environment capability fixture extraction published as `566532f9`: the six
exact model/provider capability fixtures moved behind the unchanged facade,
branch comparison and the remainder stayed exact, the 195-entry map and
deterministic bytes stayed exact, 181 validation tests passed, and bounded
review was clean.

Next candidate:
After this boundary, map the candidate-diff/refresh-budget/execution/freshness
report run against focused core-run report ownership before choosing a family.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-strategy ownership cleanup.

Status:
Publishing.

Selected slice:
Move
`strategy_branch.v1` and `strategy_recommendation.v1` from the facade into the
existing `Validation.ReferenceFixtures.CandidateStrategyArtifacts` leaf beside
its four related fixtures. Preserve the following study-benchmark fixture
exactly.

Why this slice:
`ReferenceFixtures` remains the largest production module at 3,379 lines. The
two fixtures occupy 104 facade lines and are the only fixtures owned by
`candidate_strategy_fixture_test.exs` that remain outside its existing leaf.

Current coupling/problem:
Strategy branch and recommendation expectations remain in the facade while the
other four candidate-strategy fixtures already live together. Moving the final
pair completes established family ownership without creating another module.

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
All six candidate-strategy fixtures exist only in the established leaf, all 41
fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the same
195-entry map and deterministic term bytes, both following boundary fixtures
and the complete facade remainder stay exact, focused and full validation tests
pass, and bounded review finds no blocker.

Verification gaps:
- None for this slice.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected two-fixture map: deterministic digest
  `49daba95d0db6c44e6454d713be5eae2918be0fc2d9281b97c2cda72142b15ef`.
- Existing four-fixture candidate-strategy leaf: deterministic digest
  `5254bc49379694e676f7912155a3171e02c50a8258e190664377c4a1a52e8651`;
  expected combined six-fixture digest
  `f4b58d8bff3e910ea5127f6fb445309e2381fff9fe1769268a6490e124d673ee`.
- Exact 193-entry remainder: deterministic digest
  `de93509350d869d96051f93171fa50a69b0070d11398e736f5f3c2143a760a92`.
- Source boundary confirmed at facade lines 283-386, followed by
  `study_benchmark.v1`, with no facade helper-attribute dependency in the
  selected literals.
- Normalized-AST proof against selection commit `d0e05a90`: both moved
  literals, all four existing target literals, the combined six-entry leaf, the
  following benchmark fixture, and the complete 43-entry facade remainder are
  exact.
- Post-move exact proof: the 195-entry map, sorted-key digest, selected pair
  digest, combined six-fixture leaf digest, and exact 193-entry remainder digest
  all match their selection baselines.
- Source partition proof: 41 maps total 195 entries, the completed
  candidate-strategy leaf owns six, the facade owns 43, all 820 pairwise
  intersections are empty, and the source key union exactly matches the runtime
  map.
- Facade proof: all 195 successful `fetch/1` results, missing-key `:error`, and
  nonbinary `FunctionClauseError` behavior remain unchanged.
- Focused candidate-strategy/facade validation: 18 tests passed.
- Full validation family: 181 tests passed.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review against selection commit `d0e05a90` was clean:
  the moved and existing target literals, completed leaf, facade remainder, and
  boundary fixture are normalized-AST exact; all runtime, partition, focused,
  full-test, dependency, and hygiene checks reproduced.

Behavior/schema changes:
None.

Outcome:
The strategy branch and recommendation fixtures now live beside the existing
four candidate-strategy fixtures in the established leaf. The facade shrank
from 3,379 to 3,275 lines; the leaf grew from 285 to 389 lines and owns exactly
the six fixtures exercised together.

Last completed slice:
Objective-scoring extraction published as `96a0115c`: the exact four-fixture
family moved into a new 234-line leaf, the facade shrank from 3,603 to 3,379
lines, the 195-entry map and all deterministic digests stayed exact, 16 focused
and 181 full validation tests passed, and bounded review was clean.

Next candidate:
Select the candidate-strategy ownership cleanup described above, capture the
pair, existing leaf, combined-family, and facade remainder baselines, then
complete the existing test-owned family.

Blocked:
No.

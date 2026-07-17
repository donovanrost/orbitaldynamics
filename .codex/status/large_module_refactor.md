# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-strategy ownership cleanup.

Status:
Ready for next slice selection.

Selected slice:
No implementation selected yet. The next bounded candidate is to move
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
- Next candidate still requires a selection baseline before implementation.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected four-fixture map: deterministic digest
  `7f26f969db342eb91a4fea5b06a5f68f3bed35d12ac4fa473d60b8d92ae30fec`.
- Exact 191-entry remainder: deterministic digest
  `47d11af1a98d05dcce5e24ab73470c338a38d19e20caef4bf8a346bb02731d4c`.
- Contiguous source boundary confirmed at facade lines 282-507, followed by
  `strategy_branch.v1`, with no facade helper-attribute dependency in the
  selected literals.
- Normalized-AST proof against selection commit `a5f75723`: all four moved
  literals, the following strategy-branch fixture, and the complete 45-entry
  facade remainder are exact; the new leaf owns only the intended four keys.
- Post-move exact proof: the 195-entry map, sorted-key digest, selected
  four-fixture digest, and exact 191-entry remainder digest all match their
  selection baselines.
- Source partition proof: 41 maps total 195 entries, the new leaf owns four, the
  facade owns 45, all 820 pairwise intersections are empty, and the source key
  union exactly matches the runtime map.
- Facade proof: all 195 successful `fetch/1` results, missing-key `:error`, and
  nonbinary `FunctionClauseError` behavior remain unchanged.
- Focused objective-scoring/facade validation: 16 tests passed.
- Full validation family: 181 tests passed.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review against selection commit `a5f75723` was clean:
  the contiguous source range and complete facade remainder are normalized-AST
  exact, all runtime and partition invariants reproduced, dependency direction
  remains one-way, and focused/full tests and hygiene gates passed.

Behavior/schema changes:
None.

Outcome:
No candidate-strategy ownership cleanup has started.

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

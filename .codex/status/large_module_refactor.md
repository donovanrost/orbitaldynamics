# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Objective-scoring fixture mapping.

Status:
Publishing.

Selected slice:
Move
`objective_satisfaction_report.v1`, `objective_tradeoff_report.v1`,
`score_term_report.v1`, and `ranking_comparison_report.v1` from their
contiguous facade range into a new
`Validation.ReferenceFixtures.ObjectiveScoringArtifacts` leaf. Preserve the
following strategy-branch fixture exactly.

Why this slice:
`ReferenceFixtures` remains the largest production module at 3,603 lines. The
four fixtures occupy 226 facade lines and exactly own
`objective_scoring_fixture_test.exs`.

Current coupling/problem:
Objective satisfaction, tradeoff, score-term, and ranking expectations form one
contiguous test-owned family but remain embedded in the general registry.
Moving all four preserves scoring responsibility without absorbing strategy
artifacts.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.ObjectiveScoringArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/objective_scoring_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused objective-scoring and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The four objective-scoring fixtures exist only in the new cohesive leaf, all 41
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
The exact four-fixture objective-scoring family now lives in a new cohesive
leaf behind the unchanged facade. The facade shrank from 3,603 to 3,379 lines;
the new leaf is 234 lines and owns exactly four fixtures.

Last completed slice:
Resource-summary extraction published as `e97ed85b`: the exact three-fixture
family moved into a new 207-line leaf, the facade shrank from 3,800 to 3,603
lines, the 195-entry map and all deterministic digests stayed exact, 15 focused
and 181 full validation tests passed, and bounded review was clean.

Next candidate:
Select the objective-scoring extraction described above, capture the exact map
and contiguous source boundary, then move the complete test-owned family.

Blocked:
No.

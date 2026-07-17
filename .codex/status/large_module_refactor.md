# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation objective-scoring fixture test-family extraction.

Status:
Selected.

Selected slice:
Move the four contiguous objective-satisfaction, objective-tradeoff,
score-term, and ranking-comparison fixture tests into a focused module with one
shared builder owner.

Why this slice:
After the resource-summary split, `validation_test.exs` is 10,786 lines. Tests
7,153-7,613 form a coherent objective-scoring and ranking family and end before
schema-validation fixtures. Their eight observation/raw builders plus the
campaign-plan score-term comparison builder form one closure; only observation
builders remain needed by the deterministic aggregate.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact objective,
tradeoff, score-term, ranking, stale-data coverage, and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/objective_scoring_fixture_test.exs`
- `test/support/validation/objective_scoring_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted objective-scoring fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
All four tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names remain
unique, and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Validation resource-summary fixture extraction published as `52815a6d`: the
focused module passed 3/3, the parent passed 85/85, and all twenty-two
Validation modules preserved the 181-test aggregate with no duplicate names.
Format, diff hygiene, dependency-closure checks, and bounded review were clean.

Next candidate:
Refresh the adjacent objective-satisfaction, tradeoff, score-term, and ranking
comparison fixture cluster in the 10,786-line parent. Select only a coherent
multi-test boundary and move shared builders to one support owner rather than
copying them.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation objective-scoring fixture test-family extraction.

Status:
Published as `39fede23`.

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
Four byte-identical objective-scoring family tests moved into a 479-line
focused module. Nine observation/raw/campaign-comparison builders now have one
53-line shared support owner; the parent imports only the four aggregate
observation builders, with no private residue. The parent fell from 10,786 to
10,291 lines. Total test/support/loader LOC grew by 38 lines for explicit
ownership without helper duplication. All 181 Validation test names remain
unique.

Verification gaps:
- Full repository suite not run; this is a test-only ownership extraction.

Last completed slice:
Validation objective-scoring fixture extraction published as `39fede23`: the
focused module passed 4/4, the parent passed 81/81, and all twenty-three
Validation modules preserved the 181-test aggregate with no duplicate names.
Format, diff hygiene, dependency-closure checks, and bounded review were clean.

Next candidate:
Refresh the adjacent schema-validation, batch, migration, and future-contract
challenge fixture cluster in the 10,291-line parent. Select only a coherent
multi-test boundary and move shared builders to one support owner rather than
copying them.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation candidate-strategy artifact fixture test-family extraction.

Status:
Selected.

Selected slice:
Move the six contiguous proposed-contact, branch-comparison,
optimizer-contract, invalidated-candidate, strategy-branch, and
strategy-recommendation fixture tests into a focused module with one shared
candidate-strategy fixture owner.

Why this slice:
After the planning-input split, `validation_test.exs` is 4,797 lines. Tests
1,675-2,032 form a coherent candidate-strategy artifact family and end before
benchmarks. Their twelve raw/observation helpers form a complete JSON fixture
closure; only the six observation helpers remain deterministic aggregate
consumers.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact proposed-contact,
branch comparison, optimizer, invalidation, strategy branch/recommendation
schema checks, stale artifact coverage, and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/candidate_strategy_fixture_test.exs`
- `test/support/validation/candidate_strategy_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted candidate-strategy artifact fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
All six tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names remain
unique, and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Validation planning-input capability extraction published as `3aa5fb12`: the
focused module passed 3/3, the parent passed 37/37, and all thirty-seven
Validation modules preserved the 181-test aggregate with no duplicate names.
Format, diff hygiene, exact-source and dependency-closure checks, and bounded
review were clean.

Next candidate:
Map the study benchmark fixture family following candidate strategy. Preserve
all distributed/runtime benchmark variants and split only its complete helper
closure.

Blocked:
No.

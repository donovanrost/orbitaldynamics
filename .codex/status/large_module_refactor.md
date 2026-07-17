# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation candidate-strategy artifact fixture test-family extraction.

Status:
Published as `7c5aeacf`.

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
Six byte-identical candidate-strategy artifact tests moved into a 379-line
focused module. Their twelve raw/observation helpers now have one 63-line shared
support owner with an exact private JSON loader; the parent imports only the six
aggregate observation builders. The parent fell from 4,797 to 4,395 lines.
Total test/support/loader LOC grew by 41 lines for explicit ownership without
helper duplication. All 181 Validation test names remain unique.

Verification gaps:
- Full repository suite not run; this is a test-only ownership extraction.

Last completed slice:
Validation candidate-strategy artifact extraction published as `7c5aeacf`: the
focused module passed 6/6, the parent passed 31/31, and all thirty-eight
Validation modules preserved the 181-test aggregate with no duplicate names.
Format, diff hygiene, exact-source and dependency-closure checks, and bounded
review were clean.

Next candidate:
Map the study benchmark fixture family following candidate strategy. Preserve
all distributed/runtime benchmark variants. Its one high-signal test and
sixteen raw/observation helpers form a complete closure ending before validation
reference reports.

Blocked:
No.

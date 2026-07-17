# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation benchmark artifact fixture test-family extraction.

Status:
Selected.

Selected slice:
Move the study-benchmark fixture test and all runtime/distributed benchmark
variants into a focused module with one shared benchmark fixture owner.

Why this slice:
After the candidate-strategy split, `validation_test.exs` is 4,395 lines. Test
1,685-1,791 is a high-signal benchmark family covering eight runtime/distributed
variants and ends before validation-reference reports. Its sixteen
raw/observation helpers form a complete JSON fixture closure; only the eight
observation helpers remain deterministic aggregate consumers.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact study benchmark
schema checks, runtime/distributed variant coverage, stale benchmark coverage,
and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/benchmark_fixture_test.exs`
- `test/support/validation/benchmark_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted benchmark artifact fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
The benchmark test moves mechanically with order and assertion strength
unchanged; all runtime/distributed variants and shared builders have one exact
owner, focused and parent files pass, names remain unique, and bounded review
finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Validation candidate-strategy artifact extraction published as `7c5aeacf`: the
focused module passed 6/6, the parent passed 31/31, and all thirty-eight
Validation modules preserved the 181-test aggregate with no duplicate names.
Format, diff hygiene, exact-source and dependency-closure checks, and bounded
review were clean.

Next candidate:
Map the validation-reference, candidate-diff, refresh-budget, execution, and
freshness report fixture families following benchmarks. Split only a coherent
report family with complete helper closure.

Blocked:
No.

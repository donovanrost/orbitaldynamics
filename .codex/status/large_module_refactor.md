# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation model-acceptance/safety-case fixture test-family extraction.

Status:
Selected.

Selected slice:
Move the two contiguous model-acceptance report and validation safety-case
summary fixture tests into a focused module with one shared builder owner.

Why this slice:
After the station reservation/provider split, `validation_test.exs` is 8,921
lines. Tests 1,596-2,012 form a coherent validation-evidence family and end
before candidate-refresh replay coverage. Their four observation/raw builders
form one closure; only the two observation builders remain needed by the
deterministic aggregate.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`,
`model_acceptance_report/2`, exact model-acceptance and validation safety-case
schema checks, stale-evidence coverage, and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/model_acceptance_fixture_test.exs`
- `test/support/validation/model_acceptance_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted model-acceptance/safety-case fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
Both tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names remain
unique, and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Validation station reservation/provider fixture extraction published as
`d5b34867`: the focused module passed 9/9, the parent passed 68/68, and all
twenty-five Validation modules preserved the 181-test aggregate with no
duplicate names. Format, diff hygiene, exact-source and dependency-closure
checks, and bounded review were clean.

Next candidate:
Map the candidate-refresh artifact and replay cluster beginning at line 2,013
in the 8,921-line parent. Split only along coherent replay responsibility
boundaries with complete helper closure; do not turn the entire multi-domain
replay sequence into one oversized test module.

Blocked:
No.

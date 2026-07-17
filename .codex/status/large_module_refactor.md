# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation model-acceptance/safety-case fixture test-family extraction.

Status:
Published as `da789d0c`.

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
Two byte-identical model-acceptance/safety-case family tests moved into a
430-line focused module. All four observation/raw builders now have one 35-line
shared support owner; the parent imports only the two aggregate observation
builders. The parent fell from 8,921 to 8,484 lines. Total
test/support/loader LOC grew by 29 lines for explicit ownership without helper
duplication. All 181 Validation test names remain unique.

Verification gaps:
- Full repository suite not run; this is a test-only ownership extraction.

Last completed slice:
Validation model-acceptance/safety-case fixture extraction published as
`da789d0c`: the focused module passed 2/2, the parent passed 66/66, and all
twenty-six Validation modules preserved the 181-test aggregate with no duplicate
names. Format, diff hygiene, exact-source and dependency-closure checks, and
bounded review were clean.

Next candidate:
Map the candidate-refresh base artifact and resource-provenance fixture pair,
currently lines 1,602-1,704 in the 8,484-line parent. Their four raw/observation
helpers form a closed base-artifact family, while both observation helpers
remain deterministic-aggregate consumers; stop before contact-contention replay
coverage.

Blocked:
No.

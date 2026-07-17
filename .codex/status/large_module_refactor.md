# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation core run-report fixture test-family extraction.

Status:
Ready to publish.

Selected slice:
Move the five contiguous validation-reference, candidate-diff, refresh-budget,
execution, and freshness report fixture tests into a focused module with one
shared core run-report fixture owner.

Why this slice:
After the benchmark split, `validation_test.exs` is 4,228 lines. Tests
1,697-2,213 form a coherent core run-report family and end before manifest
fixtures. Their ten raw/observation helpers form a complete JSON fixture
closure; only the five observation helpers remain deterministic aggregate
consumers.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact validation,
candidate-diff, budget, execution, and freshness schema checks, stale report
coverage, and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/core_run_report_fixture_test.exs`
- `test/support/validation/core_run_report_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted core run-report fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
All five tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names
remain unique, and bounded review finds no blocker.

Outcome:
Five byte-identical core run-report tests moved into a 536-line focused module.
Their ten raw/observation helpers now have one 54-line shared support owner with
an exact private JSON loader; the parent imports only the five aggregate
observation builders. The parent fell from 4,228 to 3,675 lines. Total
test/support/loader LOC grew by 38 lines for explicit ownership without helper
duplication. All 181 Validation test names remain unique.

Verification gaps:
- Full repository suite not run; this is a test-only ownership extraction.

Last completed slice:
Validation benchmark artifact extraction published as `616561c7`: the focused
module passed 1/1, the parent passed 30/30, and all thirty-nine Validation
modules preserved the 181-test aggregate with no duplicate names. Format, diff
hygiene, exact-source and dependency-closure checks, and bounded review were
clean.

Next candidate:
Map the manifest-field and study-manifest-lint fixtures following core reports.
The two contiguous tests and four raw/observation helpers form a complete
manifest family ending before approval/policy fixtures.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation decision-support fixture test-family extraction.

Status:
Published as `7169adcd`.

Selected slice:
Move the three contiguous maneuver-review, Monte Carlo reproducibility, and
Pareto-frontier report fixture tests into a focused module with one shared
builder owner.

Why this slice:
After the link-capacity split, `validation_test.exs` is 11,769 lines. Tests
7,126-7,430 form a coherent decision-support evidence family and end before
resource-projection fixtures. Their six observation/raw builders form one
closure; only observation builders remain needed by the deterministic
aggregate.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact maneuver review,
reproducibility, Pareto analysis, stale-data coverage, and deterministic
reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/decision_support_fixture_test.exs`
- `test/support/validation/decision_support_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted decision-support fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
All three tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names remain
unique, and bounded review finds no blocker.

Outcome:
Three byte-identical decision-support family tests moved into a 320-line
focused module. Six observation/raw builders now have one 38-line shared support
owner; the parent imports only the three aggregate observation builders, with
no private residue. The parent fell from 11,769 to 11,444 lines. Total
test/support/loader LOC grew by 34 lines for explicit ownership without helper
duplication. All 181 Validation test names remain unique.

Verification gaps:
- Full repository suite not run; this is a test-only ownership extraction.

Last completed slice:
Validation decision-support fixture extraction published as `7169adcd`: the
focused module passed 3/3, the parent passed 92/92, and all nineteen Validation
modules preserved the 181-test aggregate with no duplicate names. Format, diff
hygiene, dependency-closure checks, and bounded review were clean.

Next candidate:
Refresh the adjacent resource-projection report/flow and battery-handoff
fixture cluster in the 11,444-line parent. Select only a coherent multi-test
boundary and move shared builders to one support owner rather than copying
them.

Blocked:
No.

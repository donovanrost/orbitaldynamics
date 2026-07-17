# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation resource-projection report fixture test-family extraction.

Status:
Selected.

Selected slice:
Move the two contiguous resource-projection report and projection-flow summary
fixture tests into a focused module with one shared builder owner.

Why this slice:
After the decision-support split, `validation_test.exs` is 11,444 lines. Tests
7,133-7,283 form a coherent resource-projection report family and end before
battery-handoff fixtures. Their four observation/raw builders form one closure;
only observation builders remain needed by the deterministic aggregate. The
battery-handoff test is excluded because it deliberately spans core,
operator-review, and Cadence-import fixture families.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact resource
projection, flow summary, stale-data coverage, and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/resource_projection_fixture_test.exs`
- `test/support/validation/resource_projection_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted resource-projection fixture module directly
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

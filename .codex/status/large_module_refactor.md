# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation resource-summary fixture test-family extraction.

Status:
Selected.

Selected slice:
Move the three contiguous resource-summary, resource-filter report, and
resource-filter summary fixture tests into a focused module with one shared
builder owner.

Why this slice:
After the resource-safety split, `validation_test.exs` is 11,031 lines. Tests
7,146-7,370 form a coherent resource summary/filter family and end before
objective-scoring fixtures. Their six observation/raw builders form one
closure; only observation builders remain needed by the deterministic
aggregate.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact resource summary,
filtering, stale-data coverage, and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/resource_summary_fixture_test.exs`
- `test/support/validation/resource_summary_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted resource-summary fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
All three tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names remain
unique, and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Validation resource-safety fixture extraction published as `d3b2034a`: the
focused module passed 2/2, the parent passed 88/88, and all twenty-one
Validation modules preserved the 181-test aggregate with no duplicate names.
Format, diff hygiene, dependency-closure checks, and bounded review were clean.

Next candidate:
Refresh the adjacent resource-summary and resource-filter report/summary
fixture cluster in the 11,031-line parent. Select only a coherent multi-test
boundary and move shared builders to one support owner rather than copying
them.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation resource-summary fixture test-family extraction.

Status:
Published as `52815a6d`.

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
Three byte-identical resource-summary family tests moved into a 240-line
focused module. Six observation/raw builders now have one 38-line shared support
owner; the parent imports only the three aggregate observation builders, with
no private residue. The parent fell from 11,031 to 10,786 lines. Total
test/support/loader LOC grew by 34 lines for explicit ownership without helper
duplication. All 181 Validation test names remain unique.

Verification gaps:
- Full repository suite not run; this is a test-only ownership extraction.

Last completed slice:
Validation resource-summary fixture extraction published as `52815a6d`: the
focused module passed 3/3, the parent passed 85/85, and all twenty-two
Validation modules preserved the 181-test aggregate with no duplicate names.
Format, diff hygiene, dependency-closure checks, and bounded review were clean.

Next candidate:
Refresh the adjacent objective-satisfaction, tradeoff, score-term, and ranking
comparison fixture cluster in the 10,786-line parent. Select only a coherent
multi-test boundary and move shared builders to one support owner rather than
copying them.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation contact contention fixture test-family extraction.

Status:
Selected.

Selected slice:
Move the five contiguous contact-filter, contact-contention, cross-station
contention challenge, contention-resolution report, and resolution-summary
fixture tests into a focused module with one shared builder owner.

Why this slice:
After the provider capacity-pack split, `validation_test.exs` is 12,602 lines.
Tests 7,109-7,548 form a coherent filter-to-contention-resolution family and end
before link-capacity fixtures. Their ten observation/raw builders form one
closure; the five observation builders remain needed by the deterministic
aggregate, and the raw cross-station report remains needed by a candidate-refresh
challenge builder.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact filtering,
contention, cross-station challenge, resolution, stale-data coverage, and
deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/contact_contention_fixture_test.exs`
- `test/support/validation/contact_contention_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted contact contention fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
All five tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names remain
unique, and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Validation provider capacity-pack fixture extraction published as `94b5578b`:
the focused module passed 2/2, the parent passed 103/103, and all sixteen
Validation modules preserved the 181-test aggregate with no duplicate names.
Format, diff hygiene, dependency-closure checks, and bounded review were clean.

Next candidate:
Refresh the adjacent contact-filter, contention, and contention-resolution
fixture cluster in the 12,602-line parent. Select only a coherent multi-test
boundary and move shared builders to one support owner rather than copying
them.

Blocked:
No.

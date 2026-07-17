# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation manifest fixture test-family extraction.

Status:
Selected.

Selected slice:
Move the two contiguous manifest-field reference and study-manifest-lint
fixture tests into a focused module with one shared manifest fixture owner.

Why this slice:
After the core run-report split, `validation_test.exs` is 3,675 lines. Tests
1,706-1,926 form a coherent manifest family and end before approval/policy
fixtures. Their four raw/observation helpers form a complete JSON fixture
closure; only the two observation helpers remain deterministic aggregate
consumers.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact manifest-field
and study-manifest-lint schema checks, stale manifest coverage, and deterministic
reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/manifest_fixture_test.exs`
- `test/support/validation/manifest_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted manifest fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
Both tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names
remain unique, and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Validation core run-report extraction published as `1ac7b222`: the focused
module passed 5/5, the parent passed 25/25, and all forty Validation modules
preserved the 181-test aggregate with no duplicate names. Format, diff hygiene,
exact-source and dependency-closure checks, and bounded review were clean.

Next candidate:
Map the approval-requirement and policy-decision fixtures following manifests.
The two contiguous tests and four raw/observation helpers form a complete policy
decision family.

Blocked:
No.

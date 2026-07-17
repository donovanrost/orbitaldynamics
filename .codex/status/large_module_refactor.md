# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation policy-and-evidence fixture test-family extraction.

Status:
Selected.

Selected slice:
Move the four contiguous backend-acceptance-policy,
validation-tolerance-policy, validation-record, and validation-check fixture
tests into a focused module with one shared builder owner.

Why this slice:
After the state-and-maneuver split, `validation_test.exs` is 15,677 lines. Tests
6,438-6,677 form a coherent validation eligibility and evidence family and end
before timeline fixtures. Their eight builders are also used by the
deterministic aggregate, so they will move to a shared support owner imported
by both modules.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact acceptance,
tolerance, validation evidence, stale-data coverage, and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/policy_evidence_fixture_test.exs`
- `test/support/validation/policy_evidence_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted policy-and-evidence fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
All four tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names remain
unique, and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Validation state-and-maneuver fixture extraction published as `ae06ce20`: the
focused module passed 5/5, the parent passed 131/131, and all nine Validation
modules preserved the 181-test aggregate with no duplicate names. Format, diff
hygiene, dependency-closure checks, and bounded review were clean.

Next candidate:
Refresh the adjacent backend-acceptance, tolerance-policy, validation-record,
and validation-check fixture cluster in the 15,677-line parent. Select only a
coherent multi-test boundary and move deterministic-aggregate builders to one
shared support owner rather than copying them.

Blocked:
No.

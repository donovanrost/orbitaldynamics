# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation policy-and-evidence fixture test-family extraction.

Status:
Published as `3cd3d92d`.

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
Four byte-identical policy-and-evidence family tests moved into a 257-line
focused module. Eight observation/raw-fixture builders now have one 47-line
shared support owner; the parent imports only the four observation builders
used by its deterministic aggregate, with no private residue. The parent fell
from 15,677 to 15,409 lines. Total test/support/loader LOC grew by 37 lines for
explicit ownership without helper duplication. All 181 Validation test names
remain unique.

Verification gaps:
- Full repository suite not run; this is a test-only ownership extraction.

Last completed slice:
Validation policy-and-evidence fixture extraction published as `3cd3d92d`: the
focused module passed 4/4, the parent passed 127/127, and all ten Validation
modules preserved the 181-test aggregate with no duplicate names. Format, diff
hygiene, dependency-closure checks, and bounded review were clean.

Next candidate:
Refresh the adjacent timeline activity-state and lifecycle fixture cluster in
the 15,409-line parent. Select only a coherent multi-test boundary and move
deterministic-aggregate builders to one shared support owner rather than
copying them.

Blocked:
No.

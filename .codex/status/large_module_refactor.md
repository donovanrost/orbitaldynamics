# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation timeline activity-state fixture test-family extraction.

Status:
Verified and reviewed; ready to publish.

Selected slice:
Move the six contiguous timeline activity-precondition, activity-state,
approval-state, status-state, lifecycle-state, and lifecycle-summary fixture
tests into a focused module with one shared builder owner.

Why this slice:
After the policy-and-evidence split, `validation_test.exs` is 15,409 lines.
Tests 6,538-6,991 form a coherent timeline activity-state lifecycle family and
end before preservation fixtures. Their twelve observation/raw builders and six
generated-artifact builders form one closure; only observation builders remain
needed by the deterministic aggregate.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact timeline state,
transition, lifecycle, stale-data coverage, and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/timeline_activity_state_fixture_test.exs`
- `test/support/validation/timeline_activity_state_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted timeline activity-state fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
All six tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names remain
unique, and bounded review finds no blocker.

Outcome:
Six byte-identical timeline activity-state family tests moved into a 481-line
focused module. Eighteen observation/raw/generated builders now have one
262-line shared support owner; the parent imports the six aggregate observation
builders plus two raw lifecycle fixtures retained by manifest checks, with no
private residue. The parent fell from 15,409 to 14,716 lines. Total
test/support/loader LOC grew by 51 lines for explicit ownership without helper
duplication. All 181 Validation test names remain unique.

Verification gaps:
- Full repository suite not run; this is a test-only ownership extraction.

Last completed slice:
Validation policy-and-evidence fixture extraction published as `3cd3d92d`: the
focused module passed 4/4, the parent passed 127/127, and all ten Validation
modules preserved the 181-test aggregate with no duplicate names. Format, diff
hygiene, dependency-closure checks, and bounded review were clean.

Next candidate:
Refresh the adjacent timeline preservation, integrity, dependency, and summary
fixture clusters in the 14,716-line parent. Select only a coherent multi-test
boundary and move shared builders to one support owner rather than copying
them.

Blocked:
No.

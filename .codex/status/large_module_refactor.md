# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation policy-decision fixture test-family extraction.

Status:
Published as `a1c32f34`.

Selected slice:
Move the two contiguous approval-requirement and policy-decision fixture tests
into a focused module with one shared policy-decision fixture owner.

Why this slice:
After the manifest split, `validation_test.exs` is 3,442 lines. Tests
1,712-1,911 form a coherent policy-decision family and end before
resource-pressure handoffs. Their four raw/observation helpers form a complete
JSON fixture closure; only the two observation helpers remain deterministic
aggregate consumers.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact approval and
policy-decision schema checks, stale policy coverage, and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/policy_decision_fixture_test.exs`
- `test/support/validation/policy_decision_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted policy-decision fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
Both tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names
remain unique, and bounded review finds no blocker.

Outcome:
Two byte-identical policy-decision tests moved into a 213-line focused module.
Their four raw/observation helpers now have one 27-line shared support owner
with an exact private JSON loader; the parent imports only the two aggregate
observation builders. The parent fell from 3,442 to 3,230 lines. Total
test/support/loader LOC grew by 29 lines for explicit ownership without helper
duplication. All 181 Validation test names remain unique.

Verification gaps:
- Full repository suite not run; this is a test-only ownership extraction.

Last completed slice:
Validation policy-decision fixture extraction published as `a1c32f34`: the
focused module passed 2/2, the parent passed 21/21, and all forty-two Validation
modules preserved the 181-test aggregate with no duplicate names. Format, diff
hygiene, exact-source and dependency-closure checks, and bounded review were
clean.

Next candidate:
Map the resource-pressure handoff fixture family following policy decisions.
Move its six local observation/raw helpers while reusing the two existing
quality-gate/readiness raw fixture owners; end before contact-allocation
fixtures.

Blocked:
No.

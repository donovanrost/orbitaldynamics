# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation policy-decision fixture test-family extraction.

Status:
Selected.

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
Pending.

Verification gaps:
- Pending.

Last completed slice:
Validation manifest fixture extraction published as `8087071d`: the focused
module passed 2/2, the parent passed 23/23, and all forty-one Validation modules
preserved the 181-test aggregate with no duplicate names. Format, diff hygiene,
exact-source and dependency-closure checks, and bounded review were clean.

Next candidate:
Map the resource-pressure handoff fixture family following policy decisions.
Move only its complete cross-handoff helper closure.

Blocked:
No.

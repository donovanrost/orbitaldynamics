# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation policy-bundle fixture test-family extraction.

Status:
Selected; implementation not started.

Selected slice:
Move the six contiguous base, ground-network, operator-review queue,
command/contact, domain-authority, and remaining policy-bundle variant fixture
tests into a focused module with one shared builder owner.

Why this slice:
After the campaign split, `validation_test.exs` is 17,188 lines. Tests
6,394-6,789 form a six-test policy-bundle family and end before planned-activity
fixtures. Their builders are also used by the deterministic aggregate, so they
will move to a shared support owner imported by both modules.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact policy rule,
authority, validation, variant coverage, and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/policy_bundle_fixture_test.exs`
- `test/support/validation/policy_bundle_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted policy-bundle fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
All six tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names remain
unique, and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Not yet verified.

Last completed slice:
Validation campaign/result fixture extraction published as `b55ee18b`: five
tests moved into a 467-line focused module and 21 builders into a 113-line shared
owner, shrinking the parent from 17,710 to 17,188 lines. The focused module
passed 5/5, the parent 152/152, and the full family preserved 181/181.

Next candidate:
After this slice, refresh the remaining validation fixture families and prefer
another multi-test seam with an explicit helper dependency closure.

Blocked:
No.

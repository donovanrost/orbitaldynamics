# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation policy-bundle fixture test-family extraction.

Status:
Implemented, verified, reviewed, and ready to publish.

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
Six byte-identical policy-bundle family tests moved into a 429-line focused
module. Twenty-four observation/raw-fixture builders now have one 119-line
shared support owner; the parent imports only the 12 observation builders used
by its deterministic aggregate, with no private residue. The parent fell from
17,188 to 16,700 lines. Total test/support/loader LOC grew by 61 lines for
explicit ownership without helper duplication. All 181 Validation test names
remain unique.

Verification gaps:
- Full repository suite not run; this is a test-only ownership extraction.

Last completed slice:
Validation policy-bundle fixture extraction, publication pending: the focused
module passed 6/6, the parent passed 146/146, and all six Validation modules
preserved the 181-test aggregate with no duplicate names. Format, diff hygiene,
dependency-closure checks, and bounded review were clean.

Next candidate:
After this slice, refresh the remaining validation fixture families and prefer
another multi-test seam with an explicit helper dependency closure.

Blocked:
No.

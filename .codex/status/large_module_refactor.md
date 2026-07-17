# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation campaign/result artifact fixture test-family extraction.

Status:
Implemented, verified, reviewed, and ready to publish.

Selected slice:
Move the five leading campaign-plan, result-artifact/variant, repair, and strategy
reference-fixture tests into a focused module and give their shared observation
builders one test-support owner.

Why this slice:
After the core-policy split, `validation_test.exs` is 17,710 lines. Tests 30-465
form a five-test campaign/result artifact family. Their observation builders are
also used by the deterministic aggregate, so they will move to a shared support
owner imported by both modules; no helper implementation will be duplicated.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact campaign/result
artifact validation, variant coverage, paths/messages, and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/campaign_artifact_fixture_test.exs`
- `test/support/validation/campaign_artifact_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted campaign artifact fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
All five tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names remain
unique, and bounded review finds no blocker.

Outcome:
Five byte-identical campaign/result artifact tests moved into a 467-line focused
module. Twenty-one observation/raw-fixture builders plus `read_json!/1` now have
one 113-line shared support owner; the parent imports only the 12 observation
builders retained by its deterministic aggregate, with no private residue. The
parent fell from 17,710 to 17,188 lines. Total test/support/loader LOC grew by 59
lines for explicit module/import boundaries without helper duplication. All 181
Validation test names remain unique.

Verification gaps:
- Full repository suite not run; this is a test-only ownership extraction.

Last completed slice:
Validation campaign/result fixture extraction, publication pending: the focused
module passed 5/5, the parent passed 152/152, and all five Validation modules
preserved the 181-test aggregate with no duplicate names. Format, diff hygiene,
dependency-closure checks, and bounded review were clean.

Next candidate:
After this slice, refresh the remaining validation fixture families and prefer
another multi-test seam with an explicit helper dependency closure.

Blocked:
No.

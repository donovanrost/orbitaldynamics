# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation campaign/result artifact fixture test-family extraction.

Status:
Selected; implementation not started.

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
Pending.

Verification gaps:
- Not yet verified.

Last completed slice:
Validation core registry/policy extraction published as `63bf9be9`: ten
byte-identical tests moved into a 449-line focused module, shrinking the parent
from 18,144 to 17,710 lines. The focused module passed 10/10, the parent 157/157,
and all four Validation modules preserved the 181-test aggregate.

Next candidate:
After this slice, refresh the remaining validation fixture families and prefer
another multi-test seam with an explicit helper dependency closure.

Blocked:
No.

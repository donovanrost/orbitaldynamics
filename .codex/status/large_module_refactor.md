# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation schema-compatibility fixture test-family extraction.

Status:
Selected.

Selected slice:
Move the four contiguous schema-validation report, validation-batch report,
schema-migration report, and future-contract challenge fixture tests into a
focused module with one shared builder owner.

Why this slice:
After the objective-scoring split, `validation_test.exs` is 10,291 lines. Tests
7,161-7,460 form a coherent schema validation and migration compatibility
family and end before generic tolerance/determinism tests. Their eight
observation/raw/generated-challenge builders form one closure; only observation
builders remain needed by the deterministic aggregate.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact schema
validation, batch, migration, future-contract challenge, and deterministic
reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/schema_compatibility_fixture_test.exs`
- `test/support/validation/schema_compatibility_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted schema-compatibility fixture module directly
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
Validation objective-scoring fixture extraction published as `39fede23`: the
focused module passed 4/4, the parent passed 81/81, and all twenty-three
Validation modules preserved the 181-test aggregate with no duplicate names.
Format, diff hygiene, dependency-closure checks, and bounded review were clean.

Next candidate:
Refresh the adjacent schema-validation, batch, migration, and future-contract
challenge fixture cluster in the 10,291-line parent. Select only a coherent
multi-test boundary and move shared builders to one support owner rather than
copying them.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation schema-compatibility fixture test-family extraction.

Status:
Published as `42299354`.

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
Four byte-identical schema-compatibility family tests moved into a 317-line
focused module. Eight observation/raw/generated-challenge builders now have one
58-line shared support owner; the parent imports only the four aggregate
observation builders, with no private residue. The parent fell from 10,291 to
9,952 lines. Total test/support/loader LOC grew by 37 lines for explicit
ownership without helper duplication. All 181 Validation test names remain
unique.

Verification gaps:
- Full repository suite not run; this is a test-only ownership extraction.

Last completed slice:
Validation schema-compatibility fixture extraction published as `42299354`: the
focused module passed 4/4, the parent passed 77/77, and all twenty-four
Validation modules preserved the 181-test aggregate with no duplicate names.
Format, diff hygiene, dependency-closure checks, and bounded review were clean.

Next candidate:
Refresh the remaining 9,952-line parent inventory and select the next largest
coherent multi-test fixture family. Leave the generic tolerance/determinism tail
in place unless its helper closure forms a real focused verification unit.

Blocked:
No.

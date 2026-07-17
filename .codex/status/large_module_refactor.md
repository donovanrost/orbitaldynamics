# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Cadence-import proposed-contact/planned-activity test-family extraction.

Status:
Selected; implementation not started.

Selected slice:
Move the five adjacent proposed-contact and planned-activity import tests into a
focused input-artifact module, preserving station-calendar trust evidence and
malformed Cadence-import-context review gating.

Why this slice:
After two splits, the parent remains 16,502 lines. Lines 4,866-5,184 form five
adjacent inline-fixture tests with a shared proposed/planned input boundary and
station-calendar evidence theme; the next test begins realized-activity feedback
semantics, providing a clear family boundary.

Public facade to preserve:
`OrbitalDynamics.CadenceImport.from_proposed_contact/1`, planned-activity import
dispatch through `OrbitalDynamics.CadenceImport.manifest/1`,
`OrbitalDynamics.Schema.validate_artifact/1`, exact manifest rows/counts,
station-calendar trust evidence, review gating, and deterministic ordering.

Likely files:
- `test/orbital_dynamics/cadence_import_test.exs`
- `test/orbital_dynamics/cadence_import/activity_input_test.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted activity-input test module directly
- original Cadence import test ledger
- format, diff hygiene, and bounded review

Definition of done:
All five tests move mechanically with assertion strength and edge coverage
unchanged; the original ledger no longer duplicates them, both focused and
original-ledger test files pass, and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Not yet verified.

Last completed slice:
Cadence-import candidate-rejection test-family extraction published as
`abc57076`: two byte-identical tests moved into a 200-line focused module,
shrinking the parent from 16,696 to 16,502 lines. The focused module passed 2/2,
the parent 107/107, and the full Cadence family remained 113/113; format, diff
hygiene, and bounded review were clean.

Blocked:
No.

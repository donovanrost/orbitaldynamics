# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Cadence-import proposed-contact/planned-activity test-family extraction.

Status:
Implemented, verified, reviewed, and ready to publish.

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
Exactly five contiguous proposed-contact/planned-activity tests moved byte-for-
byte into `OrbitalDynamics.CadenceImport.ActivityInputTest`; assertion order,
station-calendar trust evidence, malformed-context gating, and async execution
are unchanged. The parent fell from 16,502 to 16,183 lines and the new focused
module is 325 lines. All 113 Cadence import test names remain unique across the
parent and three extracted modules.

Verification gaps:
- Full repository suite not run; this is a mechanical test-only extraction.

Last completed slice:
Cadence-import activity-input test-family extraction, publication pending: the
focused module passed 5/5 and the parent passed 102/102; with prior extracted
modules, the complete Cadence family remains 113/113 with no duplicate names.
Format, diff hygiene, helper-independence checks, and bounded review were clean.

Blocked:
No.

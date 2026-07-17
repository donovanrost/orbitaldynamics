# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Cadence-import realized-activity test-family extraction.

Status:
Selected; implementation not started.

Selected slice:
Move the four adjacent realized-activity and realized-state-snapshot import tests
into a focused module, preserving nested source-review drift, provider match
status mapping, and snapshot activity behavior.

Why this slice:
After three splits, the parent remains 16,183 lines. Lines 4,866-5,049 form four
adjacent realized-input tests with inline fixtures and no helper-tail dependency;
the next test begins the separate standalone contact-intent family.

Public facade to preserve:
Realized-activity and realized-state-snapshot import dispatch through
`OrbitalDynamics.CadenceImport.manifest/1`,
`OrbitalDynamics.Schema.validate_artifact/1`, exact manifest rows/counts,
source-review evidence, provider status mapping, and deterministic ordering.

Likely files:
- `test/orbital_dynamics/cadence_import_test.exs`
- `test/orbital_dynamics/cadence_import/realized_activity_test.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted realized-activity test module directly
- original Cadence import test ledger
- format, diff hygiene, and bounded review

Definition of done:
All four tests move mechanically with assertion strength and edge coverage
unchanged; the original ledger no longer duplicates them, both focused and
original-ledger test files pass, and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Not yet verified.

Last completed slice:
Cadence-import activity-input test-family extraction published as `aa73fce6`:
five byte-identical tests moved into a 325-line focused module, shrinking the
parent from 16,502 to 16,183 lines. The focused module passed 5/5, the parent
102/102, and the full 113-test family remained unique and green; format, diff
hygiene, and bounded review were clean.

Blocked:
No.

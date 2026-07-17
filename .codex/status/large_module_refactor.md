# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Cadence-import realized-activity test-family extraction.

Status:
Implemented, verified, reviewed, and ready to publish.

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
Exactly four contiguous realized-activity/snapshot tests moved byte-for-byte into
`OrbitalDynamics.CadenceImport.RealizedActivityTest`. Its one fixture-loading
call receives an exact local copy of the five-line `read_json!/1` helper; the
parent retains its copy for ten remaining consumers. The parent fell from 16,183
to 15,999 lines and the focused module is 196 lines. All 113 Cadence import test
names remain unique across the parent and four extracted modules.

Verification gaps:
- Full repository suite not run; this is a mechanical test-only extraction.

Last completed slice:
Cadence-import realized-activity test-family extraction, publication pending:
the focused module passed 4/4 and the parent passed 98/98; across all extracted
modules the full family remains 113/113 with no duplicate names. Format, diff
hygiene, helper-copy review, and bounded review were clean.

Blocked:
No.

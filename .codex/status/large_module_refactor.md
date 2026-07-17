# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Cadence-import candidate-rejection test-family extraction.

Status:
Implemented, verified, reviewed, and ready to publish.

Selected slice:
Move the adjacent standalone candidate-rejection-report and invalidated-candidate
import tests as one coherent rejection family into a focused module, preserving
their full source-review drift and manifest-count validation coverage.

Why this slice:
After the first split, the parent ledger remains 16,696 lines. Lines 4,866-5,059
form two adjacent rejection/invalidation tests with inline fixtures and no
private-helper dependency; together they cover the producer report and its
standalone invalidated-candidate boundary.

Public facade to preserve:
`OrbitalDynamics.CadenceImport.from_candidate_rejection_report/1`,
`OrbitalDynamics.CadenceImport.from_invalidated_candidate/1`,
`OrbitalDynamics.Schema.validate_artifact/1`, exact manifest rows/counts,
source-review handoff drift, and deterministic ordering.

Likely files:
- `test/orbital_dynamics/cadence_import_test.exs`
- `test/orbital_dynamics/cadence_import/candidate_rejection_test.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted candidate-rejection test module directly
- original Cadence import test ledger
- format, diff hygiene, and bounded review

Definition of done:
Both tests move mechanically with assertion strength and edge coverage
unchanged; the original ledger no longer duplicates them, both focused and
original-ledger test files pass, and bounded review finds no blocker.

Outcome:
Exactly two adjacent rejection/invalidation tests moved byte-for-byte into
`OrbitalDynamics.CadenceImport.CandidateRejectionTest`; assertion order, source
review drift checks, manifest-count checks, and async execution are unchanged.
The parent ledger fell from 16,696 to 16,502 lines and the new helper-independent
focused module is 200 lines. Unique-name and aggregate-count checks confirm no
duplicate or orphaned tests.

Verification gaps:
- Full repository suite not run; this is a mechanical test-only extraction.

Last completed slice:
Cadence-import candidate-rejection test-family extraction, publication pending:
the focused module passed 2/2 and the parent passed 107/107; together with the
existing four-test candidate-diff module, the Cadence family remains 113/113.
Format, diff hygiene, helper-independence checks, and bounded review were clean.

Blocked:
No.

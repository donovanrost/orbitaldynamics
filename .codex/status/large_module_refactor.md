# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Cadence-import candidate-rejection test-family extraction.

Status:
Selected; implementation not started.

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
Pending.

Verification gaps:
- Not yet verified.

Last completed slice:
Cadence-import candidate-diff test-family extraction published as `1d24e772`:
four byte-identical tests moved into a 298-line focused module, shrinking the
parent from 16,988 to 16,696 lines. The focused module passed 4/4 and the parent
109/109, preserving the 113-test aggregate; format, diff hygiene, and bounded
review were clean.

Blocked:
No.

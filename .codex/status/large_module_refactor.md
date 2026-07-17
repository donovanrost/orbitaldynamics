# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Cadence-import candidate-diff test-family extraction.

Status:
Implemented, verified, reviewed, and ready to publish.

Selected slice:
Move the four standalone candidate-diff import tests as one coherent family out
of the 16,988-line append-only Cadence import ledger into a focused test module,
preserving their full valid, retained-change, unpaired, and ambiguous semantics.

Why this slice:
Live inventory now shows `test/orbital_dynamics/cadence_import_test.exs` at
16,988 lines, the second-largest test ledger. Lines 5,019-5,310 form a cohesive
four-test candidate-diff family with inline fixtures and no dependence on the
large module's private helper tail, making focused verification materially
cheaper without weakening assertions.

Public facade to preserve:
`OrbitalDynamics.CadenceImport.from_candidate_diff_report/1`,
`OrbitalDynamics.Schema.validate_artifact/1`, exact manifest rows/counts,
semantic-change edge cases, and deterministic ordering.

Likely files:
- `test/orbital_dynamics/cadence_import_test.exs`
- `test/orbital_dynamics/cadence_import/candidate_diff_test.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted candidate-diff test module directly
- original Cadence import test ledger
- format, diff hygiene, and bounded review

Definition of done:
All four tests move mechanically with assertion strength and edge coverage
unchanged; the original ledger no longer duplicates them, both focused and
original-ledger test files pass, and bounded review finds no blocker.

Outcome:
Exactly four complete candidate-diff tests moved byte-for-byte into
`OrbitalDynamics.CadenceImport.CandidateDiffTest`; their order, assertions, edge
coverage, and async execution are unchanged. The parent ledger fell from 16,988
to 16,696 lines, while the new focused module is 298 lines and has no dependency
on the parent's private helper tail. Unique test-name and aggregate-count checks
confirm no duplicate or orphaned cases.

Verification gaps:
- Full repository suite not run; this is a mechanical test-only extraction.

Last completed slice:
Cadence-import candidate-diff test-family extraction, publication pending: the
new focused module passed 4/4 in 0.1 seconds and the remaining parent ledger
passed 109/109, preserving the prior 113-test aggregate. Format, diff hygiene,
helper-independence checks, and bounded review were clean.

Blocked:
No.

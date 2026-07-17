# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Cadence-import candidate-diff test-family extraction.

Status:
Selected; implementation not started.

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
Pending.

Verification gaps:
- Not yet verified.

Last completed slice:
Cadence-import-row primitive callback-boundary collapse published as `d361199c`:
11 generic dependencies and 90 runtime indirections disappeared while the
131-key domain boundary stayed exact. Three hundred seven focused and 24 export
tests passed; the broader suite produced the baseline-proven 1,340/1,345 result.
Compile, checked-in export regeneration, xref, format, diff hygiene, and bounded
review were clean.

Blocked:
No.

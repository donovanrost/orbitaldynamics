# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Suppression-handoff callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Replace the 6-entry bag shared by suppression duplicate-row and duplicate-group
validation with direct primitive/error ownership and one explicit duplicate-
evidence validator.

Why this slice:
Live inventory leaves `schema.ex` at 11,641 lines. The 293-line suppression
handoff owner routes four shared primitives and its own error construction
through lookup; only duplicate-evidence validation is a genuine Schema
composition boundary.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, the existing suppression-handoff
public functions, duplicate row/count/index evidence paths, exact messages and
issue ordering, report consumers, and exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/suppression_handoff_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused contact/resource suppression, schema, replay, and operator-review tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No suppression-handoff callback bag or lookup/apply trampolines remain; direct
shared owners preserve duplicate validation while duplicate evidence remains
an explicit boundary; focused, broader, and export checks pass; and bounded
review finds no blocker.

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.

Last completed slice:
Timeline-publication-handoff callback-bag collapse published as `303baa5f`:
`schema.ex` fell from 11,650 to 11,641 lines and its owner from 801 to 795. The
3-entry bag became two direct primitives and one summary-validator boundary.
173 focused, 1,167 broader, and 22 export tests passed; compile, xref, format,
diff hygiene, checked-in regeneration, and bounded review were clean.

Blocked:
No.

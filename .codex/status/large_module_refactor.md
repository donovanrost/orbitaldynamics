# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline-diff-summary callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Remove the 13-entry callback bag from `TimelineDiffSummaryContracts`. Call
primitive, collection, stable-ID, and timeline-diff-row owners directly and
pass the facade-derived timeline model-limit list as data through both schema
call paths.

Why this slice:
Live inventory shows `schema.ex` remains the dominant production hotspot at
12,479 lines. The 278-line summary owner contains 13 callback trampolines, and
the row cleanup removed its nested callback dependency. Top-level validation
and optional publication-source validation share the same bag, while focused
timeline summary/report tests cover counts, IDs, grouped maps, rows, and paths.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and all timeline diff summary and
publication-source behavior, including validation order, paths/messages,
model-limit comparison, row-derived counts/IDs, grouped stable-ID maps, nested
row validation, deterministic errors, and exports.

Likely extraction target:
`TimelineDiffSummaryContracts.validate/4` retains arity four but accepts the
timeline model-limit list instead of callbacks; remove the schema factory and
owner trampolines, and update both schema call paths with identical data.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_diff_summary_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- timeline summary/report contracts and focused timeline diff workflows
- schema export trio and checked-in export/fingerprint verification
- broader timeline/candidate-refresh checks, xref, format, and diff hygiene

Definition of done:
No summary callback factory or trampolines remain; both callers pass identical
model-limit data; direct owners preserve exact behavior; focused/broader/export
checks pass; and bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.

Last completed slice:
Timeline-diff-report callback collapse published as `e5bd3cb4`: `schema.ex`
fell from 12,504 to 12,479 lines and its owner from 292 to 209; 10 focused,
8 reviewer-focused, 882 broader, and 22 export tests passed; checked-in schemas
were unchanged; bounded review found no issues.

Blocked:
No.

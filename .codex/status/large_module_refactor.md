# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline-integrity-report callback-bag collapse.

Status:
Completed; ready to publish.

Selected slice:
Remove the 16-entry callback bag from `TimelineIntegrityReportContracts`. Call
primitive, collection, and stable-ID owners directly, pass timeline model-limit
data through both report paths, and preserve direct row validation across all
three facade call paths.

Why this slice:
Live inventory shows `schema.ex` remains the dominant production hotspot at
12,442 lines. The 650-line integrity owner contains 16 callback trampolines,
and its top-level report, optional nested report, and optional nested row paths
share the same bag. Focused timeline summary, timeline workflow, and
candidate-refresh provenance tests cover issue types, counts, IDs, rows,
nested evidence, and exact error paths.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and all timeline-integrity report
and nested-source behavior, including validation order, paths/messages,
model-limit comparison, issue evidence, allowed actions/types, row-derived
counts/IDs/maps, deterministic errors, and exports.

Likely extraction target:
`TimelineIntegrityReportContracts.validate/4` retains arity four but accepts
timeline model-limit data; `validate_row/4` becomes direct-owner
`validate_row/3`. Remove the schema factory and owner trampolines, pass identical
model-limit data through both report paths, and call the row owner directly.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_integrity_report_contracts.ex`
- `test/orbital_dynamics/schema/timeline_summary_contracts_test.exs`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- timeline summary contracts and focused timeline-integrity workflows
- candidate-refresh provenance tests for nested integrity sources
- schema export trio and checked-in export/fingerprint verification
- broader timeline/candidate-refresh checks, xref, format, and diff hygiene

Definition of done:
No timeline-integrity callback factory or trampolines remain; all three facade
paths use direct owners with identical model-limit data where applicable; exact
behavior is preserved; focused/broader/export checks pass; and bounded review
finds no blocker.

Result:
Removed the 16-entry callback factory and all owner-local trampolines. Both
report paths now pass exact `timeline_report_model_limits()` data, nested row
validation uses `validate_row/3`, and the owner calls primitive, collection,
and stable-ID modules directly. Review caught and the implementation restored
the former optional-map type check before stable-ID array-map validation, with
a focused wrong-type regression assertion. `schema.ex` fell from 12,442 to
12,420 lines and the owner from 650 to 555 lines.

Verification:
- compile with warnings as errors passed
- 28 focused integrity, provenance, and transition-handoff tests passed
- 882 broader timeline/candidate-refresh tests passed after the review fix
- 22 schema-export tests passed
- checked-in schema export reproduction produced no diff
- format, diff hygiene, scoped callback residue, and compile-connected xref passed
- bounded review's must-fix was resolved; re-review found no remaining issues

Verification gaps:
- Full repository suite not run.

Last completed slice:
Timeline-integrity-report callback collapse: `schema.ex` fell from 12,442 to
12,420 lines and its owner from 650 to 555; 28 focused, 882 broader, and 22
export tests passed; checked-in schemas were unchanged; bounded review's
must-fix was resolved and re-review found no remaining issues.

Blocked:
No.

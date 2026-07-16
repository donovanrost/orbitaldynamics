# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline-dependency-impact-summary callback-bag collapse.

Status:
Completed; ready to publish.

Selected slice:
Remove the 13-entry callback bag from
`TimelineDependencyImpactSummaryContracts`. Call primitive, collection, and
stable-ID owners directly and pass the facade-derived timeline model-limit list
as data. Preserve direct row validation for all three facade call paths.

Why this slice:
Live inventory shows `schema.ex` remains the dominant production hotspot at
12,461 lines. The 379-line dependency-impact owner still contains 13 callback
trampolines. Its top-level summary, optional publication-source summary, and
optional publication-source row paths all share the same bag, while focused
timeline summary and candidate-refresh provenance tests cover nested rows,
counts, IDs, scopes, and error paths.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and all timeline dependency-impact
summary and publication-source behavior, including validation order,
paths/messages, model-limit comparison, required row fields, allowed operator
actions/reasons, row-derived counts/IDs, deterministic errors, and exports.

Likely extraction target:
`TimelineDependencyImpactSummaryContracts.validate/4` retains arity four but
accepts timeline model-limit data; `validate_row/4` can become direct-owner
`validate_row/3`. Remove the schema factory and owner trampolines, pass identical
model-limit data through both summary paths, and call the row owner directly.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_dependency_impact_summary_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- timeline summary contracts and focused timeline dependency-impact workflows
- candidate-refresh provenance tests for nested source summaries
- schema export trio and checked-in export/fingerprint verification
- broader timeline/candidate-refresh checks, xref, format, and diff hygiene

Definition of done:
No dependency-impact-summary callback factory or trampolines remain; all three
call paths use direct owners with identical model-limit data where applicable;
exact behavior is preserved; focused/broader/export checks pass; and bounded
review finds no blocker.

Result:
Removed the 13-entry callback factory and all owner-local trampolines. Both
summary paths now pass exact `timeline_report_model_limits()` data; nested row
validation calls `validate_row/3`; and the owner calls primitive, collection,
and stable-ID validation modules directly. `schema.ex` fell from 12,461 to
12,442 lines and the owner from 379 to 310 lines.

Verification:
- compile with warnings as errors passed
- 21 focused summary, provenance, and publication-handoff tests passed
- reviewer reran 2 directly relevant focused cases; both passed
- 882 broader timeline/candidate-refresh tests passed
- 22 schema-export tests passed
- checked-in schema export reproduction produced no diff
- format, diff hygiene, scoped callback residue, and compile-connected xref passed
- bounded read-only review found no issues

Verification gaps:
- Full repository suite not run.

Last completed slice:
Timeline-dependency-impact-summary callback collapse: `schema.ex` fell from
12,461 to 12,442 lines and its owner from 379 to 310; 21 focused, 2
reviewer-focused, 882 broader, and 22 export tests passed; checked-in schemas
were unchanged; bounded review found no issues.

Blocked:
No.

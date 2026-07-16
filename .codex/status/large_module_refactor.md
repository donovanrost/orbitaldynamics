# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Maneuver-review-report callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Remove the 18-entry callback bag from `ManeuverReviewReportContracts`. Call
primitive, collection, and stable-ID owners directly; pass maneuver-review
model-limit data from the facade; and keep row validation and frequency
derivation local to the report owner.

Why this slice:
Live inventory shows `schema.ex` remains the dominant production hotspot at
12,420 lines. The 266-line maneuver-review owner contains 18 callback
trampolines even though it already owns report counts, rows, total delta-v, and
frequency derivation. Focused maneuver-review, schema-contract, reference
fixture, import, review, and provenance tests cover direct and nested behavior.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2` and all maneuver-review report
behavior, including source IDs, approval and uncertainty counts, model-limit
comparison, row requirements/types, delta-v vectors/totals, deterministic
errors, nested consumers, and exports.

Likely extraction target:
`ManeuverReviewReportContracts.validate/4` retains arity four but accepts the
maneuver-review model-limit list. Remove the schema factory and owner
trampolines, import direct validation owners, and replace the facade frequency
callback with equivalent owner-local derivation.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/maneuver_review_report_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- compile with warnings as errors
- maneuver-review and schema maneuver-contract tests
- focused validation fixture and nested import/review/provenance tests
- schema export trio and checked-in export/fingerprint verification
- broader maneuver/schema checks, xref, format, and diff hygiene

Definition of done:
No maneuver-review callback factory or trampolines remain; facade model-limit
data and direct owners preserve exact report/row behavior; focused/broader/export
checks pass; and bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.

Last completed slice:
Timeline-integrity-report callback collapse published as `46cd524b`:
`schema.ex` fell from 12,442 to 12,420 lines and its owner from 650 to 555; 28
focused, 882 broader, and 22 export tests passed; checked-in schemas were
unchanged; bounded review's must-fix was resolved and re-review found no issues.

Blocked:
No.

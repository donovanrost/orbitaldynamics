# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Resource-filter-report callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Replace the 16-entry `ResourceFilterReportContracts` lookup bag with direct
shared/count owners and two explicit domain row validators.

Why this slice:
Live inventory leaves `schema.ex` at 11,415 lines. This 434-line owner and its
sole caller route fourteen canonical shared/count operations and only two row
validators through lookup/apply despite having no dynamic dispatch.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, resource-filter-report fields,
assumptions, invalid/suppressed rows, derived counts, exact paths/messages/order,
consumers, deterministic artifacts, and schema exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/resource_filter_report_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused resource-filter report/summary and validation tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No resource-filter-report callback bag or lookup/apply trampolines remain;
shared/count ownership is direct and only the two domain row validators stay
explicit; focused, broader, and export checks pass; and bounded review finds no
blocker.

Verification gaps:
- Full repository suite not run.
- The broader focused batch was 113/114 because the generated campaign did not
  exactly match its checked-in golden artifact; generation is outside this
  validation-only slice. The attributable batch is 102/102.

Last completed slice:
Resource-filter-summary callback-bag collapse published as `5e614988`:
`schema.ex` fell from 11,444 to 11,415 lines and its owner from 445 to 368.
Fifteen shared or static dependencies became direct, with one value and two row
hooks explicit. Seventy-nine filter, 19 summary/fixture/lint, 1,167 broader, and
22 export tests passed; compile, xref, regeneration, format, diff hygiene, and
bounded review were clean.

Blocked:
No.

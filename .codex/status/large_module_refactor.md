# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Resource-filter-summary callback-bag collapse.

Status:
Complete and ready to publish.

Selected slice:
Replace the 18-entry `ResourceFilterSummaryContracts` lookup bag with direct
shared owners, an explicit model-limit value, and two domain validators.

Why this slice:
Live inventory leaves `schema.ex` at 11,444 lines. This 445-line owner and its
sole caller route fifteen shared/static dependencies and only two row validators
through lookup/apply despite having no dynamic dispatch.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, resource-filter-summary fields,
assumptions, row-derived counts and IDs, exact paths/messages/order, consumers,
deterministic artifacts, and schema exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/resource_filter_summary_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused resource-filter summary/report and validation tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No resource-filter-summary callback bag or lookup/apply trampolines remain;
shared/static ownership is direct and only the two domain row validators stay
explicit; focused, broader, and export checks pass; and bounded review finds no
blocker.

Outcome:
Primitive, collection, stable-ID, and aggregation work is direct; model limits
are an explicit value and the two row validators explicit guarded functions.
`schema.ex` fell from 11,444 to 11,415 lines and the owner from 445 to 368; two
orphan aggregation forwarders also disappeared. Seventy-nine filter and 19
summary/fixture/lint tests pass, alongside 1,167 broader and 22 export tests;
compile, xref, checked-in regeneration, format, and diff hygiene are clean.
Bounded review confirmed exact pipeline and derived-count order, row paths,
model limits, duplicate semantics, guards, direct-owner equivalence, and residue
removal.

Verification gaps:
- Full repository suite not run.
- The broader focused batch was 113/114 because the generated campaign did not
  exactly match its checked-in golden artifact; generation is outside this
  validation-only slice. The attributable batch is 102/102.

Last completed slice:
Resource-filter-summary callback-bag collapse, ready to publish: `schema.ex`
fell from 11,444 to 11,415 lines and its owner from 445 to 368. Fifteen shared
or static dependencies became direct, with one value and two row hooks explicit.
Seventy-nine filter, 19 summary/fixture/lint, 1,167 broader, and 22 export tests
passed; compile, xref, regeneration, format, diff hygiene, and bounded review
were clean.

Blocked:
No.

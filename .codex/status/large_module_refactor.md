# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Contact-filter-report callback-bag collapse.

Status:
Complete and ready to publish.

Selected slice:
Replace the 22-entry `ContactFilterReportContracts` lookup bag with direct
shared/count owners, local capability access, and one domain row validator.

Why this slice:
Live inventory leaves `schema.ex` at 11,395 lines. This 327-line owner and its
sole caller route shared/count validation plus eight static capability values
and only one row validator through lookup/apply despite no dynamic dispatch.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, contact-filter-report fields,
assumptions, suppressed rows, derived counts, exact paths/messages/order,
consumers, deterministic artifacts, and schema exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/contact_filter_report_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused contact-filter report and validation tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No contact-filter-report callback bag or lookup/apply trampolines remain;
shared/count/capability ownership is direct and only the suppressed-row
validator stays explicit; focused, broader, and export checks pass; and bounded
review finds no blocker.

Outcome:
Primitive, collection, stable-ID, count, and capability work is direct; only the
suppressed-candidate validator stays explicit and guarded. `schema.ex` fell from
11,395 to 11,332 lines and the owner from 327 to 254; five orphan forwarders
also disappeared. Fifty-four filter/lint and one fixture test pass, alongside
1,167 broader and 22 export tests; compile, xref, checked-in regeneration,
format, and diff hygiene are clean. All three grouped-ID fields assert preserved
duplicate type-issue multiplicity. Bounded review found no blocker: all eight
capability transformations, validation order/messages, grouped-ID duplicate
type checks, row behavior, sole-caller wiring, helper cleanup, and callback
removal preserve existing semantics.

Verification gaps:
- Full repository suite not run.
- The broader focused batch was 113/114 because the generated campaign did not
  exactly match its checked-in golden artifact; generation is outside this
  validation-only slice. The attributable batch is 102/102.

Last completed slice:
Contact-filter-report callback-bag collapse ready to publish: `schema.ex` fell
from 11,395 to 11,332 lines and its owner from 327 to 254. Primitive,
collection, stable-ID, count, and capability work became direct; only the
suppressed-candidate row validator stays explicit. Fifty-four filter/lint and
one fixture test passed, alongside 1,167 broader and 22 export tests; compile,
xref, regeneration, format, diff hygiene, and bounded review were clean.

Blocked:
No.

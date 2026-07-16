# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh-report domain callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Replace the four-entry `CandidateRefreshReportContracts` domain bag with direct
operational-readiness and validation-acceptance owners, then remove callback
arguments that otherwise only serve as list guards across the report owner.

Why this slice:
Live inventory leaves `schema.ex` at 11,332 lines. This 332-line owner and its
sole caller route three operational-readiness validators and one static count
field list through lookup/apply. The same bag is also threaded through 34
otherwise direct report validators despite no dynamic dispatch.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, candidate-refresh provenance and
source-report fields, exact paths/messages/order, safety-case counts, consumers,
deterministic artifacts, and schema exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_report_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused candidate-refresh provenance and validation tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No candidate-refresh-report domain bag, lookup/apply trampolines, or inert
callback arguments remain; operational-readiness and safety-case ownership is
direct; focused, broader, and export checks pass; and bounded review finds no
blocker.

Outcome:
Pending.

Verification gaps:
- Full repository suite not run.
- The broader focused batch was 113/114 because the generated campaign did not
  exactly match its checked-in golden artifact; generation is outside this
  validation-only slice. The attributable batch is 102/102.

Last completed slice:
Contact-filter-report callback-bag collapse published as `a345ce83`: `schema.ex` fell
from 11,395 to 11,332 lines and its owner from 327 to 254. Primitive,
collection, stable-ID, count, and capability work became direct; only the
suppressed-candidate row validator stays explicit. Fifty-four filter/lint and
one fixture test passed, alongside 1,167 broader and 22 export tests; compile,
xref, regeneration, format, diff hygiene, and bounded review were clean.

Blocked:
No.

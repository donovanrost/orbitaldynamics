# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Freshness-report exact-message restoration.

Status:
Selected; implementation pending.

Selected slice:
Restore the two implicit `"must equal #{expected}"` messages lost when
`FreshnessReportContracts` began calling the shared five-argument equality
helper directly.

Why this slice:
The full validation-file probe exposed nil messages for `$.status` and
`$.state_quality_status`. Commit `54bc2e8b` removed the callback bag but also
bypassed Schema's message-supplying five-argument wrapper; exactly two owner
calls retain that affected arity.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, freshness validation paths,
expected-value wording, issue order, consumers, and schema exports.

Likely files:
- `lib/orbital_dynamics/schema/freshness_report_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused freshness validation test and exact-message assertions
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
Both affected comparisons again emit exact expected-value messages without
changing equality semantics or issue order; focused, broader, and export checks
pass; and bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.
- The broader focused batch was 113/114 because the generated campaign did not
  exactly match its checked-in golden artifact; generation is outside this
  validation-only slice. The attributable batch is 102/102.

Last completed slice:
Result-artifact callback-bag collapse published as `6d3d0f4e`: `schema.ex` fell
from 11,513 to 11,496 lines and its owner from 231 to 187. The 12-entry bag
became direct shared validation calls plus one execution-report boundary. 102
focused, 1,167 broader, and 22 export tests passed; compile, xref, regeneration,
format, diff hygiene, and bounded review were clean.

Blocked:
No.

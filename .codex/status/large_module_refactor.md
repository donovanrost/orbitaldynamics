# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Freshness-report exact-message restoration.

Status:
Complete and ready to publish.

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

Outcome:
A local five-argument wrapper again delegates with `"must equal #{expected}"`,
while explicit-message calls continue through the shared six-argument helper.
The existing status assertion passes and state-quality wording now has its own
exact regression assertion. The full validation file passes 181/181, alongside
1,167 broader and 22 export tests; compile, xref, checked-in regeneration,
format, and diff hygiene are clean. Bounded review confirmed exact legacy
wording, unchanged ordering and nil semantics, unambiguous arity resolution,
and the strengthened assertion.

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.
- The broader focused batch was 113/114 because the generated campaign did not
  exactly match its checked-in golden artifact; generation is outside this
  validation-only slice. The attributable batch is 102/102.

Last completed slice:
Freshness-report exact-message restoration, ready to publish: the two implicit
equality checks again emit their legacy expected-value messages, and both paths
are assertion-covered. The full validation file passed 181/181, with 1,167
broader and 22 export tests; compile, xref, regeneration, format, diff hygiene,
and bounded review were clean.

Blocked:
No.

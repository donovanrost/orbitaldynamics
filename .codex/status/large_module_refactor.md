# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback throughput extraction.

Status:
Completed and pushed in `14cd441c`.

Selected boundary:
Extract numeric path lookup, planned/actual data-volume selection, data-rate
unit selection, actual-throughput derivation, duration fallback, derivation
evidence, and throughput completion fraction into
`OrbitalDynamics.TimelineFeedback.Throughput`. Preserve the existing private
numeric and throughput seams in the TimelineFeedback facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 4,766 lines, above the
  4,470-line Activity facade after its input-normalization pass.
- The selected 4,394-4,608 helper family is one throughput interpretation
  pipeline used by row construction and operational feedback.
- Generic numeric conversion remains single-owned by
  `TimelineFeedback.ExecutionUncertainty`; the new owner reuses it.
- Report assembly, matching, success-factor policy, resource feedback, and
  public report APIs remain in the facade.

Verification:
- Strict warnings-as-errors compile passed across 3,885 files.
- Focused TimelineFeedback coverage passed: 73 tests.
- Adjacent operator-review, contact-feedback-contract, and realized-activity
  feedback integration coverage passed: 10 tests.
- Exact old/new public artifact comparison against `5a8f2b1b` passed for 9
  explicit, Mbps, MB/s, nested-model, interval-duration, denominator-fallback,
  zero-value, and missing-input reports plus 9 standalone realized rows.
- Runtime xref found the new owner referenced only by the TimelineFeedback
  facade; static single-ownership review and `git diff --check` passed.
- `timeline_feedback.ex` moved from 4,766 to 4,563 lines; the dedicated owner
  is 221 lines.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback throughput extraction, selected in `5a8f2b1b` and implemented
in `14cd441c`. `timeline_feedback.ex` moved from 4,766 to 4,563 lines; the
dedicated owner is 221 lines.

Next candidate:
Re-inventory remaining TimelineFeedback numeric normalization and feedback
aggregation boundaries after throughput has one owner.

Blocked:
No.

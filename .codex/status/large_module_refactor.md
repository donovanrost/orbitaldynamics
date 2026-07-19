# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback reconciliation-identity extraction.

Status:
Completed and pushed in `eebe8828`.

Selected boundary:
Extract planned/realized identity selection and comparison for direction,
ground station, spacecraft, target, resource, collection, product, payload,
instrument, pointing, attitude, link configuration, and source window into
`OrbitalDynamics.TimelineFeedback.ReconciliationIdentity`. Move reconciliation
identity-mismatch annotation with the fields it classifies; preserve the
existing report and row assembly facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 4,508 lines. Its
  2,494-3,057 reconciliation-row assembler is the largest remaining single
  responsibility hotspot in the facade.
- Identity selection, pairwise match status, and mismatch-summary annotation
  are a cohesive subset of that assembler and depend only on planned and
  realized row maps.
- Reconciliation matching, timing, throughput, execution uncertainty,
  operational-feedback exclusion, and report aggregation remain in the
  facade.
- Existing public report APIs and artifact row shapes remain unchanged.

Verification:
- Strict warnings-as-errors compile passed across 3,891 files.
- Focused `timeline_feedback_test.exs` passed under warnings-as-errors: 73
  tests.
- Adjacent operator-review timeline-feedback, Cadence import, and contact-
  feedback schema coverage passed under warnings-as-errors: 79 tests.
- Exact public old/new comparison against `cf67ec01` passed 5 reconciliation
  reports covering matched, mismatched, planned-only, realized-only, and mixed
  identity rows.
- `mix xref callers
  OrbitalDynamics.TimelineFeedback.ReconciliationIdentity` reports only the
  TimelineFeedback facade as a runtime caller.
- Static ownership review confirms identity selection, comparison, match
  status, and mismatch-summary annotation live in the new owner.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback reconciliation-identity extraction, selected in `cf67ec01`
and implemented in `eebe8828`. `timeline_feedback.ex` moved from 4,508 to
4,376 lines; the dedicated owner is 92 lines.

Next candidate:
Re-rank the remaining large modules and select the next cohesive,
facade-preserving responsibility boundary.

Blocked:
No.

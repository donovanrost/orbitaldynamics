# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback realized-status extraction.

Status:
Completed and pushed in `efd6a8a5`.

Selected boundary:
Extract realized-status normalization, lifecycle-event interpretation,
feedback-envelope status detection, supported-status classification, and
invalid-status reason rendering into
`OrbitalDynamics.TimelineFeedback.RealizedStatus`. Preserve the existing
private status helper seams and pass facade-owned lifecycle/status collections
into the dedicated owner.

Selection evidence:
- Live re-ranking still places `timeline_feedback.ex` second at 5,023 lines.
- The selected 4,424-4,499 and 4,515-4,525 helper family owns one status
  interpretation concern used by realized-input validation and row assembly.
- Realized identity resolution, report assembly, artifact packaging, and
  lifecycle capability metadata remain in the facade.
- Focused TimelineFeedback coverage exercises direct statuses, feedback
  envelopes, lifecycle-event aliases, missing/unsupported statuses, and
  normalized public artifacts.

Verification:
- Strict warnings-as-errors compile passed across 3,879 files.
- Focused TimelineFeedback coverage passed: 73 tests.
- Adjacent operator-review, contact-feedback-contract, and realized-activity
  feedback integration coverage passed: 10 tests.
- Exact old/new public artifact comparison against `40a5a32c` passed for 12
  direct, envelope, lifecycle, unsupported, and missing-status inputs plus the
  aggregate normalized list.
- Bounded review replaced verbose repeated collection arguments with one
  facade-owned policy tuple; runtime xref found only the TimelineFeedback
  facade, static ownership review passed, and `git diff --check` passed.
- `timeline_feedback.ex` moved from 5,023 to 4,962 lines; the dedicated owner
  is 131 lines.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback realized-status extraction, selected in `40a5a32c` and
implemented in `efd6a8a5`. `timeline_feedback.ex` moved from 5,023 to 4,962
lines; the dedicated owner is 131 lines.

Next candidate:
Re-inventory remaining TimelineFeedback realized-identity and normalization
families after realized status has one production owner.

Blocked:
No.

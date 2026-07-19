# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback realized-status extraction.

Status:
Selected; implementation has not started.

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
Pending: focused TimelineFeedback baseline, exact old/new public normalized
artifacts, strict compile, adjacent realized-feedback coverage, static single
ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Study.Manifest validation-error extraction, selected in `8fde79c4` and
implemented in `3cf172e6`. `study/manifest.ex` moved from 4,613 to 4,489 lines;
the dedicated owner is 127 lines.

Next candidate:
Re-inventory remaining TimelineFeedback realized-identity and normalization
families after realized status has one production owner.

Blocked:
No.

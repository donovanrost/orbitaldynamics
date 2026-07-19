# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback identity-value consolidation.

Status:
Completed and pushed in `a02efa00`.

Selected boundary:
Move generic first-identifier lookup, metadata-aware first-value lookup,
stable identifier-list normalization, and required-ID rendering into the
existing `OrbitalDynamics.TimelineFeedback.RealizedIdentity` owner. Preserve
the facade’s private helper seams and reuse its stable-ID pattern.

Selection evidence:
- `timeline_feedback.ex` remains a top production hotspot at 4,882 lines.
- The selected 4,696-4,819 helper family duplicates stable-ID and identifier
  normalization already owned by `RealizedIdentity`.
- First-value metadata fallback remains reusable through the existing private
  facade seam; row construction and product/provider context assembly do not
  move.
- Consolidation avoids adding another narrow identity module and leaves one
  stable-ID implementation for realized and generic feedback identifiers.

Verification:
- Strict warnings-as-errors compile passed across 3,880 files.
- Focused TimelineFeedback coverage passed: 73 tests.
- Adjacent operator-review, contact-feedback-contract, and realized-activity
  feedback integration coverage passed: 10 tests.
- Exact old/new public artifact comparison against `6ddb46fc` passed for 7
  metadata fallback, nested, mixed-list, invalid, and nil product/identity
  inputs plus one reconciliation artifact.
- Runtime xref found the consolidated owner referenced only by the
  TimelineFeedback facade; static single-ownership review and
  `git diff --check` passed.
- `timeline_feedback.ex` moved from 4,882 to 4,766 lines; `RealizedIdentity`
  moved from 121 to 240 lines while the total implementation grew by 3 lines.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback identity-value consolidation, selected in `6ddb46fc` and
implemented in `a02efa00`. `timeline_feedback.ex` moved from 4,882 to 4,766
lines; `RealizedIdentity` moved from 121 to 240 lines.

Next candidate:
Re-inventory remaining TimelineFeedback scalar/map normalization and
reconciliation families after identity normalization has one owner.

Blocked:
No.

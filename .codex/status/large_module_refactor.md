# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback identity-value consolidation.

Status:
Selected; implementation has not started.

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
Pending: focused TimelineFeedback baseline, exact old/new product/identity
artifacts, strict compile, adjacent realized-feedback coverage, static single
ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback realized-identity extraction, selected in `65df60b1` and
implemented in `1b1aa4c7`. `timeline_feedback.ex` moved from 4,962 to 4,882
lines; the dedicated owner is 121 lines.

Next candidate:
Re-inventory remaining TimelineFeedback scalar/map normalization and
reconciliation families after identity normalization has one owner.

Blocked:
No.

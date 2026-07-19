# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback realized-identity extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract stable identifier validation, realized input identity selection,
identity issue classification, nested/context identifier inspection, and
invalid-row fallback identities into
`OrbitalDynamics.TimelineFeedback.RealizedIdentity`. Preserve the existing
private identity/stable-ID seams and pass the facade-owned stable-ID pattern
into the dedicated owner.

Selection evidence:
- `timeline_feedback.ex` remains the second-largest production module at 4,962
  lines after realized-status extraction.
- The selected 4,359-4,433, 4,444-4,456, and 4,466-4,474 helper family owns
  stable realized identity interpretation used by input validation, row
  assembly, and fallback invalid rows.
- Row construction, status interpretation, reconciliation, and artifact
  packaging remain in the facade; generic facade callers retain their existing
  private identifier/stable-ID seams as delegates.
- Focused TimelineFeedback coverage exercises aliases, nested identities,
  invalid identifiers, missing identifiers, fallback IDs, and deterministic
  normalized rows.

Verification:
Pending: focused TimelineFeedback baseline, exact old/new public normalized
identity artifacts, strict compile, adjacent realized-feedback coverage,
static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback realized-status extraction, selected in `40a5a32c` and
implemented in `efd6a8a5`. `timeline_feedback.ex` moved from 5,023 to 4,962
lines; the dedicated owner is 131 lines.

Next candidate:
Re-inventory remaining TimelineFeedback normalization/reconciliation families
after realized identity has one production owner.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline-context validation extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract optional timeline preconditions, activity context, protection
decisions, lifecycle transitions, timeline identity/link data, and timeline
protection summaries into `OrbitalDynamics.Schema.TimelineContextValidation`.
Preserve the existing guarded arity-3/arity-4 private Schema callback seams.

Selection evidence:
- `schema.ex` is 6,950 lines; the selected bottom-of-facade seams span
  6,868-6,885 and 6,896-6,949.
- The cluster has one responsibility: validate nested timeline and activity
  context fields consumed by campaign, import, and operator-review contracts.
- Every selected seam delegates directly to a dedicated contract module and
  has no registry, model-limit, or facade-owned callback dependency.
- Registry data, JSON Schema export, contract dispatch, unrelated validation,
  and all public `Schema` APIs remain outside.

Verification:
Pending: focused timeline-context baselines, exact old/new fixture validation
reports, strict compile, broader Schema contract tests, JSON Schema export
checks, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema policy validation extraction, selected in `253ec596` and implemented in
`e207f932`. `schema.ex` moved from 6,963 to 6,950 lines; the dedicated owner is
76 lines.

Next candidate:
Re-inventory remaining Schema family-validation clusters after timeline-context
validation has one production owner.

Blocked:
No.

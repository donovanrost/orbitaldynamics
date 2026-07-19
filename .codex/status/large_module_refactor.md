# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline-context validation extraction.

Status:
Completed and published.

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
- Strict compile passed across 3,866 files with warnings as errors.
- Focused operational-timeline, activity-state, and campaign-repair contracts
  passed: 13 tests.
- Full Schema suite passed: 175 tests.
- JSON Schema export contracts passed: 15 tests.
- Exact old/new validation reports matched for 9 valid and mutated timeline and
  operator-review fixtures spanning every selected seam.
- Static inspection confirms the facade retains only its guarded arity-3/arity-4
  callback seams; runtime xref reports `Schema` as the sole caller of the new
  owner.
- `git diff --check` and bounded ownership review passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema timeline-context validation extraction, selected in `7cc168a1` and
implemented in `07f20eef`. `schema.ex` moved from 6,950 to 6,912 lines; the
dedicated owner is 76 lines.

Next candidate:
Re-inventory remaining Schema family-validation clusters after timeline-context
validation has one production owner.

Blocked:
No.

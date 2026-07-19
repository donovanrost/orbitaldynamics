# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline-transition validation extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract timeline transition-application report, summary, row,
selected-activity, selected-integrity, and optional source validation into
`OrbitalDynamics.Schema.TimelineTransitionValidation`. Preserve the existing
private `Schema` callback seams, passing activity-context,
lifecycle-transition, and protection-decision callbacks explicitly.

Selection evidence:
- `schema.ex` is 7,141 lines; the selected contiguous cluster spans
  6,238-6,331.
- The cluster has one responsibility: validate transition-application artifacts
  and their embedded rows/source evidence.
- Its only facade-owned dependencies are three callbacks; model limits and all
  remaining validation dependencies are family-local or existing contract
  modules.
- Registry data, JSON Schema export, contract dispatch, unrelated timeline
  source validation, and all public `Schema` APIs remain outside.

Verification:
Pending: focused transition report/summary baselines, exact old/new fixture
validation reports, strict compile, broader Schema contract tests, schema export
checks, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema timeline-source validation extraction, selected in `6d33c608` and
implemented in `abaa5617`. `schema.ex` moved from 7,204 to 7,141 lines; the
dedicated owner is 135 lines.

Next candidate:
Re-inventory remaining Schema family-validation clusters after timeline
transition validation has one production owner.

Blocked:
No.

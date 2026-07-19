# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema operational-timeline validation extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract optional operational-timeline report validation and timeline-row
orchestration into `OrbitalDynamics.Schema.OperationalTimelineValidation`.
Preserve the existing arity-2 and arity-3 private Schema callback seams.

Selection evidence:
- `schema.ex` is 6,878 lines; the selected operational-timeline seams span
  6,062-6,074 and 6,084-6,095.
- The cluster has one responsibility: validate nested operational-timeline
  reports and their rows.
- Registry dispatch remains facade-owned, while timeline-context and integrity
  validators can be supplied as callbacks to the new owner.
- Registry data, JSON Schema export, contract dispatch, unrelated validation,
  and all public `Schema` APIs remain outside.

Verification:
Pending: focused operational-timeline baselines, exact old/new fixture
validation reports, strict compile, broader Schema contract tests, JSON Schema
export checks, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema operator-review validation extraction, selected in `b55ade2d` and
implemented in `818526c4`. `schema.ex` moved from 6,888 to 6,878 lines; the
dedicated owner is 46 lines.

Next candidate:
Re-inventory remaining Schema family-validation clusters after
operational-timeline validation has one production owner.

Blocked:
No.

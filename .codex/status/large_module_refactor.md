# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign planner branch event/state application extraction.

Status:
Completed and published.

Selected slice:
Extract branch plan-event and realized-event application, their station/capacity
and realized-state merge helpers, into `CampaignPlanner.BranchEventApplication`.
Consolidate station identity through the existing `BranchEventNormalizer`.

Why this slice:
The cluster owns how branch events mutate prior-plan candidates and realized
state, including station matching, reduced capacity, missed/delayed activities,
spacecraft degradation, and deterministic state merging. Moving both sides
together avoids a broad callback bag. Degraded mode/spacecraft helpers remain
explicit internal functions for branch-refresh summaries, and station identity
can reuse the existing normalizer instead of remaining duplicated.

Public facade to preserve:
All `OrbitalDynamics.CampaignPlanner` public functions, exact branch/event
artifacts, deterministic ordering, source paths, approval statuses, and trust
boundaries.

Likely files:
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/branch_event_normalizer.ex`
- new `lib/orbital_dynamics/campaign_planner/branch_event_application.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused ground-station, degraded-spacecraft, maneuver, reduced-capacity, and
  branch-feedback tests
- deterministic strategy regression coverage
- compile, format, xref, diff hygiene, and bounded review

Definition of done:
The planner delegates plan and realized-state event application and state merges
to one internal module; event order, matching, statuses, reasons, capacity
math, degradation fields, and deterministic merge ordering remain exact;
focused tests pass; and bounded review finds no blocker.

Outcome:
`CampaignPlanner` now delegates prior-plan and realized-state branch event
application plus realized-state merges to
`CampaignPlanner.BranchEventApplication`. Station identity is consolidated in
`BranchEventNormalizer`; branch-refresh callbacks use the extracted module's
spacecraft/degraded-mode readers. The facade fell from 3,316 to 3,025 lines.

Verification gaps:
- None for this slice.

Tests run:
- `mix compile --warnings-as-errors`
- 64 focused station, capacity, degradation, maneuver, realized-feedback,
  branch, facade, and determinism tests
- `mix format --check-formatted`
- `git diff --check`
- new-file diff hygiene
- compile-connected xref check for `campaign_planner.ex`
- bounded read-only review: clean, no findings

Behavior/schema changes:
None.

Last completed slice:
Campaign-planner branch event/state application published as `42abcf65`: plan
and realized event pipelines, capacity/station matching, degradation, and state
merge helpers now live in one cohesive internal module, 64 focused/regression
tests passed, and bounded review found no finding.

Next candidate:
Pivot to `schema.ex` and audit the cadence-import row JSON-provider and
contract-callback clusters. Select only a boundary whose provider/validator
dependencies can move with it; do not extract the remaining large
CampaignPlanner orchestration functions through broad callback bags.

Blocked:
No.

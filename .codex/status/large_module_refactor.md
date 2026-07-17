# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign planner operator-review pressure-branch dispatch extraction.

Status:
Completed and published.

Selected slice:
Extract the 22-review-type operator-review row pressure-branch registry from
`OrbitalDynamics.CampaignPlanner` into
`CampaignPlanner.OperatorReviewPressureBranches`.

Why this slice:
The live hotspot inventory shows `CampaignPlanner` remains 3,967 lines, and
about 500 lines are one cohesive adapter registry keyed by `review_type`. It
owns review-row source extraction, approval/trust-boundary propagation, and
dispatch into family pressure builders. The two facade collectors and all
strategy behavior can remain unchanged.

Public facade to preserve:
All `OrbitalDynamics.CampaignPlanner` public functions, exact branch/event
artifacts, deterministic ordering, source paths, approval statuses, and trust
boundaries.

Likely files:
- `lib/orbital_dynamics/campaign_planner.ex`
- new `lib/orbital_dynamics/campaign_planner/operator_review_pressure_branches.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused strategy operator-review row/comms/feedback/objective tests
- deterministic strategy regression coverage
- compile, format, xref, diff hygiene, and bounded review

Definition of done:
The planner collectors delegate row dispatch to one internal registry; all 22
review types, fallback behavior, source paths, policy use, trust boundaries,
and emitted branch artifacts remain exact; focused tests pass; and bounded
review finds no blocker.

Outcome:
All three callers now delegate operator-review row dispatch to
`CampaignPlanner.OperatorReviewPressureBranches`. The internal module owns all
22 review-type clauses, the unknown-row fallback, source extraction,
approval/trust-boundary propagation, and the registry-only communications and
timeline-diff wrappers. `CampaignPlanner` fell from 3,967 to 3,592 lines.

Verification gaps:
- None for this slice.

Tests run:
- `mix compile --warnings-as-errors`
- 29 focused operator-review/objective/timeline/communications tests
- 10 campaign facade and strategy branch regression tests
- `mix format --check-formatted`
- `git diff --check`
- new-file diff hygiene
- compile-connected xref check for `campaign_planner.ex`
- bounded read-only review: clean, no findings

Behavior/schema changes:
None.

Last completed slice:
Campaign-planner operator-review pressure dispatch published as `72f92514`:
all 22 review types and the unknown fallback now live in one cohesive internal
registry, all three callers delegate through it, 39 focused/regression tests
passed, and bounded review found no finding.

Next candidate:
After this slice, audit the adjacent cadence-import pressure registry or the
remaining branch-refresh helper cluster; select only one cohesive boundary.

Blocked:
No.

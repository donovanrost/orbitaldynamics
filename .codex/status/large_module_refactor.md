# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign planner operator-review pressure-branch dispatch extraction.

Status:
Selected.

Selected slice:
Extract the 21-clause operator-review row pressure-branch registry from
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
The planner collectors delegate row dispatch to one internal registry; all 21
review types, fallback behavior, source paths, policy use, trust boundaries,
and emitted branch artifacts remain exact; focused tests pass; and bounded
review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Schema quality-gate report property dispatch published as `91313036`:
operational quality-gate summary and quality-gate report now route through one
cohesive internal dispatcher, 30 focused/export tests passed, full regeneration
was byte-identical, and bounded review found no finding.

Next candidate:
After this slice, audit the adjacent cadence-import pressure registry or the
remaining branch-refresh helper cluster; select only one cohesive boundary.

Blocked:
No.

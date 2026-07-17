# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign planner branch candidate-plan staging extraction.

Status:
Selected.

Selected slice:
Extract branch event candidate-plan staging from
`OrbitalDynamics.CampaignPlanner` into `CampaignPlanner.BranchCandidatePlan`.

Why this slice:
The cluster owns one complete transformation: initialize a candidate plan,
stage urgent-target, downlink-completion, candidate-diff-replacement, and
capacity-adjustment events, preserve warnings, and deterministically sort the
result. Its replacement lookup, deduplication, and invalid-event helpers are
single-purpose. Only station-ID normalization is shared, requiring one narrow
facade callback rather than a broad callback bag.

Public facade to preserve:
All `OrbitalDynamics.CampaignPlanner` public functions, exact branch/event
artifacts, deterministic ordering, source paths, approval statuses, and trust
boundaries.

Likely files:
- `lib/orbital_dynamics/campaign_planner.ex`
- new `lib/orbital_dynamics/campaign_planner/branch_candidate_plan.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused urgent-target, downlink-completion, candidate-diff, reduced-capacity,
  and branch-basics tests
- deterministic strategy regression coverage
- compile, format, xref, diff hygiene, and bounded review

Definition of done:
The planner delegates candidate-plan construction to one internal module;
event precedence, warnings, replacement selection, additions, capacity
adjustments, ordering, and returned tuple remain exact; focused tests pass; and
bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Campaign-planner cadence-import pressure aggregation published as `02c913fb`:
both source collectors, embedded-review precedence, and direct fallback now
live in one cohesive internal aggregator, 26 focused tests passed, and bounded
review found no finding.

Next candidate:
After this slice, audit branch plan-event versus realized-event application as
separate responsibilities. Do not combine them if shared state helpers would
require broad callback plumbing.

Blocked:
No.

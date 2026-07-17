# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign planner branch candidate-plan staging extraction.

Status:
Completed and published.

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
`CampaignPlanner` now delegates candidate-plan construction to
`CampaignPlanner.BranchCandidatePlan` with one narrow station-ID callback. The
internal module owns initialization, four event-family staging paths,
replacement lookup/deduplication, warnings, additions, capacity adjustments,
and deterministic result ordering. The facade fell from 3,530 to 3,316 lines.

Verification gaps:
- None for this slice.

Tests run:
- `mix compile --warnings-as-errors`
- 77 focused staged-event, branch, facade, and determinism tests
- `mix format --check-formatted`
- `git diff --check`
- new-file diff hygiene
- compile-connected xref check for `campaign_planner.ex`
- bounded read-only review: clean, no findings

Behavior/schema changes:
None.

Last completed slice:
Campaign-planner branch candidate-plan staging published as `f071d63f`: all
four staged event families, replacement helpers, warnings, and deterministic
ordering now live in one cohesive internal module, 77 focused/regression tests
passed, and bounded review found no finding.

Next candidate:
After this slice, audit branch plan-event versus realized-event application as
separate responsibilities. Do not combine them if shared state helpers would
require broad callback plumbing.

Blocked:
No.

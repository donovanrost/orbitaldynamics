# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: derived-branch collection extraction.

Status:
Ready to publish.

Selected slice:
Moved baseline/combined branch addition, normalization, explicit-ID filtering,
family disambiguation, deduplication, and stable sorting behind
`CampaignPlanner.DerivedBranchCollection`.

Why this slice:
The post-source pipeline owns one cohesive branch-collection invariant and moved
without callback plumbing. Individual source derivation remains in the parent.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/derived_branch_collection.ex`

Public APIs preserved:
- `OrbitalDynamics.CampaignPlanner.strategy/1`
- `OrbitalDynamics.CampaignPlanner.strategy!/1`
- `OrbitalDynamics.CampaignPlanner.strategy_from_file!/2`

Behavior/schema changes:
None. The extraction preserves pipeline order and the final deterministic sort.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Combined-derived, strategy pressure-family, and branch-basics tests: 152/156
  passed. The four failures were isolated and reproduce unchanged at baseline
  commit `2ee7206e` (22/26 in both worktrees).
- `mix xref callers OrbitalDynamics.CampaignPlanner.DerivedBranchCollection`
  passed with the expected single parent caller.
- `mix xref graph --source lib/orbital_dynamics/campaign_planner/derived_branch_collection.ex`
  passed.
- `mix format`, `git diff --check`, no-index-artifact scan, and conflict-marker
  scan passed.

Verification gaps:
- The full suite was not rerun for this behavior-preserving extraction.
- Existing focused failures remain in source-report resource pressure, contact
  filter pressure, resource filter pressure, and readiness-row risk penalty.

Last commit:
`2ee7206e` (`Extract strategy resource impacts`); current slice is not yet
committed.

Next candidate:
Reassess `evaluate_branch/2` after publishing. Its final result assembly is
cohesive, but the current input surface is broad enough that a direct extraction
could become parameter plumbing rather than a clean responsibility boundary.

Blocked:
No.

Notes:
- `campaign_planner.ex` decreased from 4,645 to 4,602 lines in this slice.
- `maybe_add_derived_branches/6` decreased from 165 to 125 lines.
- `DerivedBranchCollection` is 58 lines.
- Earlier published slices in this run: V2 repair artifact assembly (`207e7c71`),
  V3 strategy feedback adjustments (`9354a88f`), and V3 strategy resource
  impacts (`2ee7206e`).

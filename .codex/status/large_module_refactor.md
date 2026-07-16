# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: V3 strategy resource-impact extraction.

Status:
`CampaignPlanner.evaluate_branch/2` now delegates resource-source precedence,
margin/capacity calculation, availability normalization, warning/risk creation,
and resource score adjustment to `CampaignPlanner.StrategyResourceImpacts`.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/strategy_resource_impacts.ex`

Public APIs preserved:
- `OrbitalDynamics.CampaignPlanner.strategy/1`
- `OrbitalDynamics.CampaignPlanner.strategy!/1`
- `OrbitalDynamics.CampaignPlanner.strategy_from_file!/2`

Behavior/schema changes:
- No intended public behavior or schema changes.
- Fuel, power, storage, downlink, and thermal margin precedence is unchanged.
- Spacecraft, payload, and antenna availability fallback/alias behavior is unchanged.
- Risk thresholds, warnings, fuel-preservation flag, and score adjustments are unchanged.
- Downlink requirements and completion call existing focused modules directly;
  three now-redundant parent wrappers were removed.

Tests run:
- `mix compile --warnings-as-errors` - passed.
- All strategy resource/downlink test files plus branch basics - passed, 155 tests.
- `mix xref callers OrbitalDynamics.CampaignPlanner.StrategyResourceImpacts` -
  passed; runtime caller is `CampaignPlanner`.
- `mix xref graph --label compile-connected --source lib/orbital_dynamics/campaign_planner.ex`
  - passed; the new module is a compile-connected dependency.
- `mix format --check-formatted` on the ledger and touched source files - passed.
- `git diff --check` - passed.
- `git diff --no-index --check -- /dev/null` on the new module - passed with no
  whitespace diagnostics.
- Conflict-marker scan and bounded local review - passed.

Verification gaps:
- Full `mix test` was not run.
- `strategy_branch_generated_candidate_refresh_test.exs` retains its known
  refresh-budget replay expectation mismatch, previously reproduced unchanged
  at pre-refactor commit `c6aaecf0`.

Last commit:
`27bca2a0` before this slice; publish pending.

Next candidate:
Extract the post-source derived-branch collection pipeline from
`maybe_add_derived_branches/6` into `CampaignPlanner.DerivedBranchCollection`:
baseline/combined branch addition, normalization, explicit-ID filtering,
family disambiguation, deduplication, and stable sorting. Keep individual source
derivation in the parent so the boundary does not require a callback bag.

Blocked:
No.

Notes:
- `campaign_planner.ex` decreased from 5,128 to 4,645 lines.
- `StrategyResourceImpacts` is 493 lines and owns one explicit V3 resource
  scoring responsibility.
- Earlier published slices in this run: V2 repair artifact assembly (`207e7c71`)
  and V3 strategy feedback adjustments (`9354a88f`).

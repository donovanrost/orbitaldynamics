# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: V3 strategy feedback adjustment extraction.

Status:
`CampaignPlanner.evaluate_branch/2` now computes normalized branch operational
feedback and delegates factor calculation, source labeling, risk generation,
and score adjustment to `CampaignPlanner.StrategyFeedbackAdjustments`.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/strategy_feedback_adjustments.ex`

Public APIs preserved:
- `OrbitalDynamics.CampaignPlanner.strategy/1`
- `OrbitalDynamics.CampaignPlanner.strategy!/1`
- `OrbitalDynamics.CampaignPlanner.strategy_from_file!/2`

Behavior/schema changes:
- No intended public behavior or schema changes.
- Contact, observation, image-quality, cloud-cover, blur, maneuver, command, and
  station-throughput factors preserve the same defaults and averaging rules.
- Risk thresholds, score adjustment, source labels, and feedback-weight source
  ordering are unchanged.
- The parent still owns normalized branch feedback derivation, avoiding callback
  plumbing for event/station/spacecraft identity.

Tests run:
- `mix compile --warnings-as-errors` - passed.
- All `strategy*feedback*_test.exs` files plus strategy branch basics - passed,
  168 tests.
- `mix xref callers OrbitalDynamics.CampaignPlanner.StrategyFeedbackAdjustments`
  - passed; runtime caller is `CampaignPlanner`.
- `mix xref graph --label compile-connected --source lib/orbital_dynamics/campaign_planner.ex`
  - passed; the new module is a compile-connected dependency.
- `mix format --check-formatted` on the ledger and touched source files - passed.
- `git diff --check` - passed.
- `git diff --no-index --check -- /dev/null` on the new module - passed with no
  whitespace diagnostics.
- Conflict-marker scan and bounded local review - passed.

Verification gaps:
- Full `mix test` was not run.
- Adjacent `strategy_branch_generated_candidate_refresh_test.exs` remains 3/4
  with a refresh-budget replay assertion expecting no pressure while the runtime
  reports pressure. The identical failure was reproduced at pre-refactor commit
  `c6aaecf0`, so it is an existing unrelated mismatch rather than a regression
  from either current extraction.

Last commit:
`9354a88f` (`Extract strategy feedback adjustments`).

Next candidate:
Extract the cohesive `branch_resource_impacts/3` cluster and its margin,
availability, risk, and score helpers into
`CampaignPlanner.StrategyResourceImpacts`. Call `DownlinkObjectiveRequirements`
and `StrategyMetrics` directly so the boundary does not introduce callbacks.

Blocked:
No.

Notes:
- `campaign_planner.ex` decreased from 5,527 to 5,128 lines.
- `StrategyFeedbackAdjustments` is 413 lines and owns one explicit V3 scoring
  responsibility.
- This run also completed and published V2 repair artifact assembly as
  `207e7c71`; that slice passed 62 repair/facade/baseline tests.

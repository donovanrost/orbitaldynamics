# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner V3 branch-evaluation boundary extraction.

Status:
Slice selected; implementation not started.

Selected slice:
Move `evaluate_branch/2` and its branch-only assessment helpers from
`CampaignPlanner` into an internal `CampaignPlanner.StrategyBranchEvaluation`
boundary. Inject only the facade-preserving normalized `repair/1` entry point.

Why this slice:
After the V2 repair-execution extraction, `CampaignPlanner` is 1,802 lines. Its
remaining 169-line evaluator still coordinates the complete V3 branch lifecycle
and is followed by branch-only warning, risk, approval, objective, feasibility,
assumption, and provenance helpers.

Current coupling/problem:
The public facade directly owns branch event application, candidate refresh,
V2 repair invocation, candidate-plan construction, resource and feedback
assessment, objective satisfaction, feasibility, risk, approval, strategic
scoring, warning aggregation, assumptions, provenance, and `PlanBranch`
construction. This is one cohesive V3 evaluation responsibility.

Public facade to preserve:
`CampaignPlanner.strategy/1`, `strategy!/1`, repair entry points, file-backed
entry points, branch ordering, `PlanBranch` fields, scores, risks, approvals,
warnings, reports, provenance, deterministic output, and all error behavior.

Likely files:
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/strategy_branch_evaluation.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
`do_strategy_with_baseline/1` delegates each branch to
`StrategyBranchEvaluation.evaluate/3`; only normalized `repair/1` is injected;
branch artifacts, ordering, policy application, warnings, scoring, provenance,
and errors are unchanged; focused and full planner tests match live baseline;
strict compile and independent review are clean.

Verification gaps:
- The full planner directory has five previously documented failures. The
  post-change run must retain the same 728/733 result and observations.
- The exact focused branch-evaluation baseline still needs to be captured.

Tests run:
- Live inventory: `CampaignPlanner` is 1,802 lines.
- Usage mapping confirms the selected branch assessment helpers are evaluator
  only. Shared V1 metrics remain in the facade; the new owner can call
  `StrategyMetrics` directly.
- Dependency mapping found one required seam: the facade's normalized
  `repair/1` entry point. All other work uses existing internal owners.
- No runtime code has changed in this slice.

Behavior/schema changes:
None intended.

Outcome:
Pending.

Last completed slice:
V2 repair-execution boundary published as implementation `bb696784` and handoff
`bc064c2c`: `CampaignPlanner` shrank from 1,894 to 1,802 lines; focused 35/35,
full-baseline, and 3,649-file compile proof passed; independent review was
clean.

Next candidate:
Implement and verify the selected V3 branch-evaluation boundary.

Blocked:
No.

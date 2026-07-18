# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner V3 branch-evaluation boundary extraction.

Status:
Implementation published as `3fecf5e0`; handoff publication pending.

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
- The full planner directory retains the five previously documented failures:
  728/733 passed with the same test names, values, and stack locations.
- Independent review was clean. No code, API, artifact, determinism, ordering,
  policy, provenance, ownership, error-behavior, or behavioral finding remains.

Tests run:
- Baseline and post-change focused branch-evaluation subset: 55 passed with
  warnings as errors.
- Post-change full planner directory: 728/733 passed with the same five
  documented failures and observations as the live baseline.
- Strict forced compile: 3,650 files clean with warnings as errors.
- Public `CampaignPlanner` definitions match selection commit `8e3e0e25`.
  Xref reports `CampaignPlanner` as the only runtime caller of the new owner.
- Format, tracked and new-file whitespace, and `git diff --check` passed. The
  selected evaluator and branch-only helpers are absent from the facade.
- `CampaignPlanner` shrank from 1,802 to 1,443 lines. The new internal
  `StrategyBranchEvaluation` module is 282 lines.
- The only injected dependency is the facade's normalized `repair/1` entry
  point. Direct internal calls replace the removed thin metric helpers.
- Independent review compared the full lifecycle and every `PlanBranch` field,
  then reran the exact 55-test subset, 3,650-file compile, public-def, xref,
  formatting, diff, and new-file checks; results matched primary proof.

Behavior/schema changes:
None intended.

Outcome:
`do_strategy_with_baseline/1` now delegates each normalized branch to
`StrategyBranchEvaluation.evaluate/3`. Cross-branch ordering, recommendation,
comparison, and artifact assembly remain in the facade. Implementation
published as `3fecf5e0`.

Last completed slice:
V2 repair-execution boundary published as implementation `bb696784` and handoff
`bc064c2c`: `CampaignPlanner` shrank from 1,894 to 1,802 lines; focused 35/35,
full-baseline, and 3,649-file compile proof passed; independent review was
clean.

Next candidate:
Publish this handoff, then refresh the remaining facade responsibilities and
select the next bounded extraction.

Blocked:
No.

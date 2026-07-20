# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CampaignPlanner strategy owner direct routing.

Status:
Completed and pushed.

Selected boundary:
Remove five one-hop CampaignPlanner helpers for strategy recommendation,
strategy prior-plan normalization, mission-state normalization, branch
generation policy, and strategy branch normalization. Route their six internal
call sites directly to the existing responsibility-owner modules. Keep public
CampaignPlanner APIs, request normalization order, strategy/repair artifact
construction, deterministic ordering, and all internal owner APIs unchanged.

Selection evidence:
- Live inventory shows CandidateRefresh and OperatorReview are already
  delegation-only facades at 524 and 505 lines; CampaignPlanner remains 1,078
  lines with 79 private functions.
- All five helpers delegate to same-arity owner APIs without guards, defaults,
  transformation, caching, or shared facade state.
- The recommendation helper additionally accepts but ignores approval policy;
  direct routing removes that misleading internal parameter without changing
  the public strategy API.
- Exact request normalization, branch ordering, recommendation content,
  repair behavior, and generated artifacts must remain unchanged.

Implementation:
Removed the five one-hop CampaignPlanner strategy-owner helpers and routed
their six call sites directly to the existing internal modules.
`campaign_planner.ex` moved from 1,078 to 1,061 lines.

Verification:
- Strict focused core planner, recommendation-explanation, and mission-state
  baseline before routing: 9 passed.
- The same strict focused suite after routing: 9 passed.
- Strict adjacent recommendation, repair-input, and repair-determinism
  coverage: 13 passed.
- `mix xref callers` for all five owner modules reports the expected
  CampaignPlanner orchestrator and existing internal consumers.
- Static search confirms all five helper definitions and indirect calls are
  gone.
- `git diff --check` passed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `f1571f1c` pushed to `main`.

Behavior/schema changes:
None. Public CampaignPlanner APIs, request normalization order, repair
behavior, branch ordering, recommendation content, and generated artifacts
remain unchanged.

Last completed slice:
CampaignPlanner strategy owner direct routing, selected in `0aec9fda` and
implemented in `f1571f1c`.
`campaign_planner.ex` moved from 1,078 to 1,061 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

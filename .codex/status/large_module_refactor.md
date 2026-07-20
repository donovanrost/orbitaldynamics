# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CampaignPlanner strategy owner direct routing.

Status:
Selected; implementation not started.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema common count-map primitive direct routing, selected in `96fd7f7d` and
implemented in `132941cb`.
`schema.ex` moved from 5,989 to 5,986 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

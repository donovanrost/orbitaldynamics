# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CampaignPlanner strategy request normalization extraction.

Status:
Completed and pushed.

Selected boundary:
Move `normalize_strategy_request/1` and its single-use operational-feedback
provenance adapter into a new internal `StrategyRequestNormalization` module.
Keep public `strategy/1`, `do_strategy/1`, feedback merge order, derived-branch
orchestration, policy normalization, timestamp validation, exact errors, and
all artifact behavior unchanged.

Selection evidence:
- `campaign_planner.ex` is 759 lines after repair request normalization.
- The selected 126-line function begins at raw strategy request fields and ends
  at the normalized map consumed by `do_strategy/1`.
- Its six-argument operational-feedback provenance helper has no other
  consumer and already delegates to OperationalFeedbackProvenance.
- Exact fallback keys, feedback precedence, provenance, derived branches,
  policies, timestamps, metadata, and deterministic strategy output must
  remain unchanged.

Implementation:
Added `StrategyRequestNormalization` and moved raw strategy-field
normalization, feedback aggregation/provenance, derived-branch merging,
policies, timestamps, and metadata behind `normalize/1`. CampaignPlanner moved
from 759 to 601 lines; the new owner is 148 lines.

Verification:
- Strict focused core planner, recommendation, mission-state, and operational
  feedback baseline before extraction: 22 passed.
- The same strict focused suite after extraction: 22 passed.
- The branch-generated candidate-refresh file was already 3/4 before editing
  and remains 3/4 with the same refresh-budget pressure expectation mismatch.
- Strict adjacent strategy recommendation and branch-repair coverage: 9 passed.
- `mix xref callers` reports CampaignPlanner as the sole
  StrategyRequestNormalization consumer and the new owner as the expected
  OperationalFeedbackProvenance and DerivedBranchOrchestration consumer.
- Strict compile removed fifteen aliases that moved with the cluster.
- Static search confirms both selected functions are gone from CampaignPlanner.
- `git diff --check` passed.
- Strict forced compile passed across 4,068 files.
- Implementation commit `73b4d57a` pushed to `main`.

Behavior/schema changes:
None. Public CampaignPlanner APIs, fallback keys, feedback merge order,
provenance, derived branches, policies, timestamps, metadata, and deterministic
strategy artifacts remain unchanged.

Last completed slice:
CampaignPlanner strategy request normalization extraction, selected in
`8676ab29` and implemented in `73b4d57a`.
`campaign_planner.ex` moved from 759 to 601 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

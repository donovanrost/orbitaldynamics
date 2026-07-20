# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CampaignPlanner strategy request normalization extraction.

Status:
Selected; implementation not started.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
CampaignPlanner repair request normalization extraction, selected in
`fb458f11` and implemented in `6c4475d1`.
`campaign_planner.ex` moved from 952 to 759 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

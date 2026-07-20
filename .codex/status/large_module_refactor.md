# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CampaignPlanner repair request normalization extraction.

Status:
Selected; implementation not started.

Selected boundary:
Move repair map-to-struct conversion, request normalization, generated-at and
ground-network validation, and optional candidate-refresh execution into a new
internal `RepairRequestNormalization` module. Keep public `repair/1`, the
ReplanRequest struct, `do_repair/1`, normalization order, exact error messages,
candidate-refresh inheritance, and all artifact behavior unchanged.

Selection evidence:
- `campaign_planner.ex` is 952 lines after the inheritance extraction.
- The selected cluster begins at raw repair request decoding and ends at the
  normalized map consumed by `do_repair/1`; its timestamp, ground-network, and
  candidate-refresh execution helpers have no other consumers.
- The cluster already delegates inheritance and candidate-source semantics to
  RepairCandidateRefreshInheritance and RepairMetadata, so those owner
  boundaries remain intact after the move.
- Exact aliases, fallback keys, policy merging, validation errors, generated
  refresh artifacts, and deterministic repair output must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
CampaignPlanner repair candidate-refresh inheritance extraction, selected in
`f7918ecb` and implemented in `727bad87`.
`campaign_planner.ex` moved from 1,037 to 952 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

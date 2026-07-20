# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CampaignPlanner repair request normalization extraction.

Status:
Completed and pushed.

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
Added `RepairRequestNormalization` and moved map-to-struct conversion, repair
normalization, timestamp/network validation, candidate-source derivation, and
optional refresh execution behind `from_map/1` and `normalize/1`.
CampaignPlanner moved from 952 to 759 lines; the new owner is 197 lines.
Strategy timestamp normalization now calls the shared owner directly.

Verification:
- Strict focused core planner, repair-input, generated-refresh,
  station-calendar, and determinism baseline before extraction: 17 passed.
- The same strict focused suite after extraction: 17 passed.
- Strict adjacent candidate-refresh filter/source-report and strategy
  recommendation/mission-state coverage: 13 passed.
- `mix xref callers` reports CampaignPlanner as the sole
  RepairRequestNormalization consumer and preserves the expected nested
  RepairCandidateRefreshInheritance and RepairMetadata dependencies.
- Strict compile caught and resolved the shared strategy timestamp consumer and
  six aliases that moved with the cluster.
- Static search confirms the selected functions are gone from CampaignPlanner.
- `git diff --check` passed.
- Strict forced compile passed across 4,067 files.
- Implementation commit `6c4475d1` pushed to `main`.

Behavior/schema changes:
None. Public CampaignPlanner APIs, ReplanRequest shape, fallback keys, policy
merging, validation errors, timestamps, ground networks, candidate-refresh
execution, and deterministic artifacts remain unchanged.

Last completed slice:
CampaignPlanner repair request normalization extraction, selected in
`fb458f11` and implemented in `6c4475d1`.
`campaign_planner.ex` moved from 952 to 759 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

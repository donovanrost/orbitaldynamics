# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema campaign branch/recommendation owner routing extraction.

Status:
Selected; implementation pending.

Selected boundary:
Add owner-default artifact entry points to `CampaignArtifactValidation` for
`strategy_branch.v1` and `strategy_recommendation.v1`. Derive requirements from
`CampaignRegistryContracts` and `StrategyManeuverRegistryContracts`, preserve
the branch schema-contract equality check before branch validation, route both
direct `Schema` clauses, and preserve every existing owner API.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,751 lines; the other
  targeted public facades are now 164 to 524 lines.
- Both clauses already delegate artifact-specific validation to
  `CampaignArtifactValidation` after facade-level setup.
- `CampaignRegistryContracts` owns branch requirements;
  `StrategyManeuverRegistryContracts` owns recommendation requirements.
- The branch's explicit schema-contract equality check can move into the owner
  without callbacks or facade-local context.
- No route needs recursive `Schema` lookup.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, validation ordering and paths, public `Schema`
and existing `CampaignArtifactValidation` APIs, validation results, and
checked-in exports must remain unchanged.

Last completed slice:
Schema decision-support owner completion, selected in `d817a431` and
implemented in `62d2790e`.
`schema.ex` moved from 4,761 to 4,751 lines.

Next candidate:
Implement and verify the selected campaign branch/recommendation owner routing,
then re-rank the remaining Schema responsibility clusters.

Blocked:
No.

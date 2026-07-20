# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema campaign branch/recommendation owner routing extraction.

Status:
Completed and pushed.

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
Added registry-backed branch and recommendation artifact entry points to
`CampaignArtifactValidation`, moved the branch schema-contract equality check
into the owner, and routed both direct `Schema` clauses through it. `schema.ex`
moved from 4,751 to 4,745 lines.

Verification:
- Strict focused baseline: 12 tests passed.
- Focused plus adjacent campaign, validation, Cadence import, fixture,
  contract, and export coverage after extraction: 88 tests passed.
- Full schema export completed with no checked-in artifact changes.
- Static routing review found exactly the two intended direct facade routes.
- `mix xref trace` confirmed both runtime calls originate in `schema.ex`.
- Formatting and `git diff --check` passed.
- Strict forced compile passed across 4,086 files with warnings as errors.
- Bounded diff review confirmed both registry-owned requirement sets, branch
  equality-check placement, branch/recommendation contract routing, validation
  ordering, and paths remain unchanged.
- Implementation committed and pushed as `b2dfd904`.

Behavior/schema changes:
None. Required fields, validation ordering and paths, public `Schema` and
existing `CampaignArtifactValidation` APIs, validation results, and checked-in
exports remain unchanged.

Last completed slice:
Schema campaign branch/recommendation owner routing extraction, selected in
`215d1587` and implemented in `b2dfd904`.
`schema.ex` moved from 4,751 to 4,745 lines.

Next candidate:
Re-rank the remaining Schema responsibility clusters and select the next
facade-preserving extraction.

Blocked:
No.

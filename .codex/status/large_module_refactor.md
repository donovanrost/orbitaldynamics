# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema plan-delta owner completion.

Status:
Complete and pushed.

Selected boundary:
Add `CampaignArtifactValidation.validate_delta_artifact/3`, using
`PlanChangeRegistryContracts` before the existing plan-delta contract. Route
the direct `plan_delta.v1` `Schema` clause through the campaign artifact owner
and preserve all existing callback APIs.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,726 lines; the other
  targeted public facades are now 164 to 524 lines.
- `CampaignArtifactValidation` already owns campaign repair validation and
  supplies `PlanDeltaContracts.validate/3` to its repair callbacks.
- `PlanChangeRegistryContracts` is the authoritative standalone plan-delta
  registry source.
- No route needs recursive `Schema` lookup.

Implementation:
Added `CampaignArtifactValidation.validate_delta_artifact/3`, which owns the
standalone plan-change registry requirements before the existing plan-delta
contract. Routed the direct `plan_delta.v1` `Schema` clause through the campaign
artifact owner. `schema.ex` moved from 4,726 to 4,724 lines; the focused owner
moved from 214 to 227 lines.

Verification:
- Strict focused baseline: 12 tests passed.
- Campaign repair, standalone schema, review, export, validation, and fixture
  adjacency: 22 tests passed.
- Full schema export regenerated with no checked-in schema artifact changes.
- Formatting, diff whitespace, bounded dependency/reference checks, and the
  bounded semantic diff review passed.
- `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force
  --warnings-as-errors` compiled 4,087 files successfully.

Behavior/schema changes:
None. Required fields, validation ordering and paths, public `Schema` and
existing `CampaignArtifactValidation` APIs, validation results, and checked-in
exports remain unchanged.

Last completed slice:
Schema plan-delta owner completion, selected in `fa79e852` and implemented in
`76260142`. `schema.ex` moved from 4,726 to 4,724 lines.

Next candidate:
Re-rank the remaining direct `Schema` validation clauses, prioritizing a
cohesive owner or owner completion without recursive `Schema` lookup or public
API changes.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema campaign-artifact validation context extraction.

Status:
Selected; implementation pending.

Selected boundary:
Add CampaignArtifactValidation owner-default plan, repair, strategy, branch,
and recommendation entry points. Derive campaign requirements from the
campaign registry, compose the plan/repair callback graphs from existing
owners, keep strategy branch/recommendation recursion inside the owner, route
all five direct Schema consumers, and remove both facade callback bags plus the
branch/recommendation wrappers. Keep every customizable contract API.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 5,191 lines; the other
  targeted public facades are now 164 to 524 lines.
- Plan and repair callback graphs now resolve entirely to primitive,
  collection, stable-ID, and existing validation/contract owners.
- Strategy recursion requires only owner-local branch/recommendation validators
  plus existing operational-feedback, decision-support, and review owners.
- CampaignRegistryContracts owns all three campaign required-field lists.
- Standalone strategy branch and recommendation consumers can route to the
  same owner defaults.
- No callback needs recursive Schema lookup or another facade-local validator.
- Existing CampaignPlanContracts, CampaignRepairContracts, and
  CampaignStrategyContracts customization APIs remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, callback ordering, validation ordering and
paths, customizable APIs, public Schema APIs, validation results, and
checked-in exports must remain unchanged.

Last completed slice:
Schema link-capacity validation routing, selected in `1f254ec7` and implemented
in `569e3c34`.
`schema.ex` moved from 5,202 to 5,191 lines.

Next candidate:
Implement and verify the selected campaign-artifact validation context
extraction, then re-rank the remaining Schema responsibility clusters.

Blocked:
No.

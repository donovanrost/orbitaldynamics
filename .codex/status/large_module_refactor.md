# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema campaign-artifact validation context extraction.

Status:
Completed and pushed.

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
Added CampaignArtifactValidation owner-default plan, repair, strategy, branch,
and recommendation entry points. Derived campaign requirements from the
campaign registry, moved both callback graphs and strategy recursion into the
owner, routed all five direct Schema consumers, removed both facade callback
bags plus the branch/recommendation wrappers, and removed stale facade
imports. All customizable campaign contract APIs remain unchanged.
`schema.ex` moved from 5,191 to 5,034 lines.

Verification:
- Strict campaign baseline before extraction: 6 passed.
- The same strict focused suite after extraction: 6 passed.
- Strict campaign, optimizer, link-capacity, and operator-review coverage: 58
  passed.
- An additional broader run passed 69 tests and exposed one checked-in
  golden-campaign versus fresh-study drift failure; this slice changes only
  validation routing and no generation path, so that artifact refresh remains
  outside this slice.
- The full schema-export task completed and produced no checked-in changes.
- Exact static inspection confirms five direct owner routes and zero facade
  campaign callback bags or branch/recommendation wrappers.
- `mix xref callers OrbitalDynamics.Schema.CampaignArtifactValidation` reports
  only the expected Schema facade runtime caller.
- `mix format --check-formatted` and `git diff --check` passed.
- Strict forced compile passed across 4,075 files with no warnings.
- Bounded local review confirmed every callback target and order, registry
  requirement, standalone branch pre-validation, and issue path are preserved.
- Implementation commit `633eab11` pushed to `main`.

Behavior/schema changes:
None. Required fields, callback ordering, validation ordering and paths,
customizable APIs, public Schema APIs, validation results, and checked-in
exports remain unchanged.

Last completed slice:
Schema campaign-artifact validation context extraction, selected in `706b4bea`
and implemented in `633eab11`.
`schema.ex` moved from 5,191 to 5,034 lines.

Next candidate:
Re-rank the remaining Schema responsibility clusters. Preserve the
context-bearing CommonJsonSchema wrappers unless a separate exact ownership
boundary is proven.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema plan-delta owner completion.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, validation ordering and paths, public `Schema`
and existing `CampaignArtifactValidation` APIs, validation results, and
checked-in exports must remain unchanged.

Last completed slice:
Schema relay data-path owner completion, selected in `30581147` and implemented
in `85701edc`. `schema.ex` moved from 4,728 to 4,726 lines.

Next candidate:
Implement and verify the selected plan-delta owner completion, then re-rank the
remaining Schema responsibility clusters.

Blocked:
No.

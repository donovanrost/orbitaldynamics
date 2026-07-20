# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema proposed-contact owner completion.

Status:
Selected; implementation pending.

Selected boundary:
Add `CampaignArtifactValidation.validate_proposed_contact_artifact/3`, using
`ProposedContactRegistryContracts` before the existing proposed-contact
contract. Route the direct `proposed_contact.v1` `Schema` clause through the
campaign artifact owner and preserve all existing callback APIs.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,724 lines; the other
  targeted public facades are now 164 to 524 lines.
- `CampaignArtifactValidation` already owns campaign plan validation and
  supplies `ProposedContactContracts.validate/3` to its plan callbacks.
- `ProposedContactRegistryContracts` is the authoritative standalone
  proposed-contact registry source.
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
Schema plan-delta owner completion, selected in `fa79e852` and implemented in
`76260142`. `schema.ex` moved from 4,726 to 4,724 lines.

Next candidate:
Implement and verify the selected proposed-contact owner completion, then
re-rank the remaining Schema responsibility clusters.

Blocked:
No.

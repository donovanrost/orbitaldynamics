# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema proposed-contact owner completion.

Status:
Complete and pushed.

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
Added `CampaignArtifactValidation.validate_proposed_contact_artifact/3`, which
owns the standalone proposed-contact registry requirements before the existing
contract. Routed the direct `proposed_contact.v1` `Schema` clause through the
campaign artifact owner. `schema.ex` moved from 4,724 to 4,722 lines; the
focused owner moved from 227 to 240 lines.

Verification:
- Strict focused baseline: 16 tests passed.
- Campaign, cadence, communications, review, export, validation, and fixture
  adjacency: 34 tests passed.
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
Schema proposed-contact owner completion, selected in `b7fc688e` and implemented
in `c6c6fc6a`. `schema.ex` moved from 4,724 to 4,722 lines.

Next candidate:
Re-rank the remaining direct `Schema` validation clauses. The remaining
contract-context and recursive routes need a fresh boundary assessment rather
than another mechanical owner completion.

Blocked:
No.

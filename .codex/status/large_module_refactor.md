# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport V1 campaign artifact orchestration extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract the V1 campaign artifact constructor orchestration into
`OrbitalDynamics.CadenceImport.CampaignArtifactImport`. Preserve
`from_campaign_artifact/2` as the public facade and pass its existing proposed
contact row, review-row, and manifest-builder seams as callbacks.

Selection evidence:
- `cadence_import.ex` is now 2,122 lines.
- The selected constructor spans about 70 lines and coordinates proposed
  contact ordering, selected review-row composition, provenance, and context.
- Its responsibility is orchestration; concrete proposed-contact/review row
  builders and manifest assembly already have separate owners.
- Public API docs, standalone proposed-contact construction, schemas, and
  V2/V3 generation imports remain outside the boundary.

Verification:
Pending: focused campaign baselines, exact old/new constructor equivalence
proof, strict compile, all combined CadenceImport tests, schema contracts,
static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport V3 strategy artifact orchestration extraction, selected in
`c7e06ba2` and implemented in `7364935c`. `cadence_import.ex` moved from 2,170
to 2,122 lines; the extracted owner is 72 lines.

Next candidate:
Re-inventory standalone proposed-contact construction or manifest routing after
V1 campaign orchestration has one production owner.

Blocked:
No.

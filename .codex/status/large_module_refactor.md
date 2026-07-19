# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport campaign-row builder extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract proposed-contact row construction, strategy row construction,
operational-feedback manifest-context construction, and their shared
branch-evidence/normalization callbacks into
`OrbitalDynamics.CadenceImport.CampaignRowBuilder`. Preserve three private
facade seams used by the existing campaign and strategy artifact orchestrators.

Selection evidence:
- `cadence_import.ex` is now 907 lines.
- Its remaining artifact-specific callback cluster spans lines 849-889 plus
  shared helpers at the tail of the facade.
- The cluster has one responsibility: adapt V1 proposed contacts and V3
  strategy branches/feedback into campaign-owned manifest rows and context.
- Public constructors, review-row construction, manifest routing/assembly,
  capability data, and schemas remain outside the boundary.

Verification:
Pending: focused proposed-contact and strategy baselines, exact old/new public
manifest proofs, strict compile, all combined CadenceImport tests, schema
contracts, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport review-row builder extraction, selected in `5cf4c17c` and
implemented in `540325fc`. `cadence_import.ex` moved from 1,415 to 907 lines;
the dedicated builder is 537 lines.

Next candidate:
Re-inventory capability metadata and the remaining generic facade seams after
campaign row construction has one production owner.

Blocked:
No.

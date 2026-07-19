# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport campaign-row builder extraction.

Status:
Completed and pushed in `60973011`.

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
- Strict warnings-as-errors compile passed across 3,845 files.
- Three focused proposed-contact/strategy tests passed.
- All 96 combined CadenceImport tests passed.
- All four CadenceImport schema-contract tests passed.
- Exact old/new public-manifest comparison passed for the checked-in campaign
  artifact, its standalone proposed contact, the checked-in V3 strategy
  artifact, and both artifacts through public manifest routing.
- Static search confirms three private facade seams and one campaign-row owner.
- Runtime xref confirms the facade owns the dependency on the new builder.
- Formatting, diff checks, and bounded review passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport campaign-row builder extraction, selected in `2cfecef1` and
implemented in `60973011`. `cadence_import.ex` moved from 907 to 866 lines; the
dedicated builder is 61 lines.

Next candidate:
Re-inventory capability metadata and the remaining generic facade seams after
campaign row construction has one production owner.

Blocked:
No.

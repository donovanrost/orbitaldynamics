# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport central manifest builder extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract normalized row assembly, manifest counts/context projection, provenance,
model limits, and assumptions into
`OrbitalDynamics.CadenceImport.ManifestBuilder`. Preserve the facade's existing
`build_manifest/3` seam as a delegate; pass schema constants, accepted statuses,
and the existing capability map from the facade. Reuse the extracted source-ID,
row-normalization, statistics, and map-normalization owners.

Selection evidence:
- `cadence_import.ex` is now 3,078 lines.
- The selected contiguous builder spans about 198 lines and is the remaining
  central owner of final manifest shape and summary aggregation.
- Row status, identifier construction, frequency rendering, model-limit
  rendering, and nil compaction already have extracted production owners.
- Public dispatch, capability construction, review-summary selection, row
  builders, schemas, and source ordering remain outside the boundary.

Verification:
Pending: focused representative manifest baselines, exact old-AST manifest
equivalence matrix, strict compile, all combined CadenceImport tests, schema
contracts, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport review-row metadata extraction, selected in `ff22d4ee` and
implemented in `8affcbb2`. `cadence_import.ex` moved from 3,087 to 3,078 lines;
the extracted owner is 21 lines.

Next candidate:
Return to remaining row dispatch after central manifest assembly has one
production owner.

Blocked:
No.

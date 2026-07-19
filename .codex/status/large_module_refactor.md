# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport central manifest builder extraction.

Status:
Completed and published.

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
- Strict test compile passed with 3,822 files and warnings as errors.
- Three focused representative manifest tests passed with 69 excluded.
- All combined CadenceImport tests passed: 96 tests.
- CadenceImport schema contracts passed: 4 tests.
- An AST proof against selection commit `caa62f6f` confirmed the new builder is
  exactly the selected function with schema/capability inputs and calls adapted
  to the extracted ID, row-normalization, statistics, and map-normalization
  owners.
- Formatting and diff checks passed, and no temporary extraction/proof files
  remain.
- Static ownership checks confirmed central assembly has one production
  implementation behind the preserved facade seam; four now-unused facade-only
  helper delegates were retired.
- Runtime xref confirmed `cadence_import.ex` is the direct consumer of
  `manifest_builder.ex`.
- Bounded local review found no manifest keys, counts, context projection,
  provenance, assumptions, limits, compaction, ordering, or schema changes.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport central manifest builder extraction, selected in `caa62f6f` and
implemented in `8e584b9a`. `cadence_import.ex` moved from 3,078 to 2,876 lines;
the extracted owner is 216 lines.

Next candidate:
Return to remaining row dispatch after central manifest assembly has one
production owner.

Blocked:
No.

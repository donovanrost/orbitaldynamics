# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport source-identifier policy extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract deterministic source and manifest identifier construction into
`OrbitalDynamics.CadenceImport.SourceIdentifierPolicy`. Move the schema
validation, schema-validation batch, execution, result-artifact, and manifest ID
builders while preserving their five existing private call seams as delegates.

Selection evidence:
- `cadence_import.ex` is now 3,604 lines.
- The selected contiguous private family spans about 47 lines and has five
  narrowly typed call sites.
- The family has one responsibility: construct deterministic colon-delimited
  source IDs and the manifest ID wrapper with the current unknown-source
  fallback.
- Option precedence, report parsing, rows, provenance, schemas, ordering, and
  manifest construction remain outside the boundary.

Verification:
Pending: focused schema/execution/result baselines, exact identifier matrix,
strict compile, all combined CadenceImport tests, schema contracts, static
single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport review-package row-source policy extraction, selected in
`f6367758` and implemented in `28be3c19`.

Next candidate:
Return to the remaining CadenceImport row-building or manifest-routing map after
source identifier construction has one production owner.

Blocked:
No.

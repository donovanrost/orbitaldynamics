# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport generic review-action policy extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract the closed review-type to import-action mapping into
`OrbitalDynamics.CadenceImport.GenericReviewActionPolicy`. Preserve the
`CadenceImport` private callback seam as a one-line delegate so both operational
readiness and generic review row builders keep their existing callback shape.

Selection evidence:
- `cadence_import.ex` is now 3,727 lines.
- The selected private clause family spans about 79 lines and has exactly two
  callback captures, both inside CadenceImport row-builder adapters.
- The family is a pure, closed policy mapping 38 known review types to stable
  import actions with one generic fallback.
- Row construction, status selection, source actions, capability metadata,
  manifest dispatch, schemas, ordering, and all other review context remain
  outside the boundary.

Verification:
Pending: focused generic-review baselines, exact mapping matrix, strict compile,
all combined CadenceImport tests, schema contracts, static single ownership,
runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport provider-result normalization extraction, selected in `1ae51c8b`
and implemented in `1fba10b1`.

Next candidate:
Return to the remaining CadenceImport row-building or manifest-routing map after
generic review-action policy has one production owner.

Blocked:
No.

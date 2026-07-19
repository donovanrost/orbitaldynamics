# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport generic review-action policy extraction.

Status:
Complete and published in `4ef7d3c9`.

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
- The pre-move generic-review focused baseline passed 2 tests from selection
  commit `c5639be1`; the mapping count was corrected in `45d53209`.
- Strict test compilation passed with warnings as errors across 3,806 files.
- The focused generic-review proof passed 2 tests; the eleven-file combined
  CadenceImport proof passed all 96 tests.
- `cadence_import_contracts_test.exs` passed all 4 tests.
- An AST-derived before/after matrix proved all 38 explicit review-type mappings
  and the generic fallback exactly.
- Formatting, tracked and new-file diff checks, static single ownership,
  temporary-checker absence, and runtime xref passed.
- Bounded local review found no callback shape, review action, fallback, row
  construction, import status, schema, ordering, or public API change.
- `cadence_import.ex` fell from 3,727 to 3,654 lines; the extracted policy is 49
  lines.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport generic review-action policy extraction, selected in `c5639be1`,
corrected in `45d53209`, and implemented in `4ef7d3c9`.

Next candidate:
Refresh the remaining CadenceImport row-building and manifest-routing map, then
select another cohesive private responsibility with a narrow facade seam.

Blocked:
No.

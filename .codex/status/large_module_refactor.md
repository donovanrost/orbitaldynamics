# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport review-package row-source policy extraction.

Status:
Complete and published in `28be3c19`.

Selected boundary:
Extract the closed source-artifact-type to operator-review-package row-source
mapping into `OrbitalDynamics.CadenceImport.ReviewPackageRowSourcePolicy`.
Preserve the existing `CadenceImport` private call seam as a one-line delegate.

Selection evidence:
- `cadence_import.ex` is now 3,654 lines.
- The selected private family spans about 53 lines and has one call site in the
  operator-review-package adapter context.
- The family is a pure mapping for 16 explicit artifact contracts plus identical
  binary and non-binary fallbacks.
- Review rows, review actions, source artifact identity, manifest construction,
  schemas, ordering, and every other operator-review field remain outside the
  boundary.

Verification:
- The pre-move standalone-review focused baseline passed 1 test from selection
  commit `f6367758`.
- Strict test compilation passed with warnings as errors across 3,807 files.
- The focused standalone-review proof passed 1 test; the eleven-file combined
  CadenceImport proof passed all 96 tests.
- `cadence_import_contracts_test.exs` passed all 4 tests.
- An AST-derived before/after matrix proved all 16 explicit contract mappings
  and both binary/non-binary fallback clauses exactly.
- Formatting, tracked and new-file diff checks, static single ownership,
  temporary-checker absence, and runtime xref passed.
- Bounded local review found no source path, fallback, review row, artifact
  identity, schema, ordering, or public API change.
- `cadence_import.ex` fell from 3,654 to 3,604 lines; the extracted policy is 53
  lines.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport review-package row-source policy extraction, selected in
`f6367758` and implemented in `28be3c19`.

Next candidate:
Refresh the remaining CadenceImport row-building and manifest-routing map, then
select another cohesive private responsibility with a narrow facade seam.

Blocked:
No.

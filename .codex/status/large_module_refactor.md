# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport candidate-diff field policy extraction.

Status:
Completed and published.

Selected boundary:
Extract candidate-diff changed-field derivation and count normalization into
`OrbitalDynamics.CadenceImport.CandidateDiffFields`. Preserve the facade's
existing derivation and count callback seams as delegates; keep semantic-change
detail field collection private to the new owner.

Selection evidence:
- `cadence_import.ex` is now 3,361 lines.
- The selected contiguous policy family spans about 18 lines and is shared by
  candidate-diff and approval-requirement row builders through stable callbacks.
- The family has one responsibility: combine explicit and semantic-detail
  changed fields, retain binary names, deduplicate/sort them, and omit the count
  when the resulting list is empty.
- Dispatch, row construction, review actions, map compaction, schemas, and
  manifest construction remain outside the boundary.

Verification:
- Strict test compile passed with 3,814 files and warnings as errors.
- Two focused candidate-refresh and approval-requirement tests passed with 70
  excluded.
- All combined CadenceImport tests passed: 96 tests.
- CadenceImport schema contracts passed: 4 tests.
- A 9-case direct decision matrix covered explicit fields, absent-key fallback,
  present-nil suppression of fallback, scalar wrapping, semantic-detail merging,
  binary filtering, uniqueness, sorting, missing data, and count normalization.
- Formatting and diff checks passed, and no temporary proof files remain.
- Static ownership checks confirmed derivation, semantic-detail collection, and
  count normalization have one production implementation behind preserved
  facade callback seams.
- Runtime xref confirmed `cadence_import.ex` is the direct consumer of
  `candidate_diff_fields.ex`.
- Bounded local review found no callback, fallback, merge, filter, order, count,
  row-shape, or schema changes.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport candidate-diff field policy extraction, selected in `47b70576`
and implemented in `84d11b0a`. `cadence_import.ex` moved from 3,361 to 3,349
lines; the extracted owner is 22 lines.

Next candidate:
Return to the remaining CadenceImport row-building or manifest-routing helpers
after candidate-diff field derivation has one production owner.

Blocked:
No.

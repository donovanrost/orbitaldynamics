# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport manifest-row status normalization extraction.

Status:
Completed and published.

Selected boundary:
Extract Cadence-import status encoding, accepted-status preservation, and
unsupported-status invalidation into
`OrbitalDynamics.CadenceImport.ManifestRowNormalization`. Preserve the facade's
existing `normalize_import_row/1` seam as a delegate and pass its advertised
status list into the new owner.

Selection evidence:
- `cadence_import.ex` is now 3,119 lines.
- The selected contiguous family spans about 33 lines and is consumed by central
  manifest assembly before row counts and summaries are calculated.
- The family has one responsibility: JSON-normalize source status values and
  turn unsupported values into explicit invalid review rows while preserving an
  existing invalid-reason override.
- Manifest assembly, aggregation, capability construction, row builders,
  schemas, and ordering remain outside the boundary.

Verification:
- Strict test compile passed with 3,819 files and warnings as errors.
- Two focused accepted/unsupported status tests passed with 70 excluded.
- All combined CadenceImport tests passed: 96 tests.
- CadenceImport schema contracts passed: 4 tests.
- A 10-case direct decision matrix covered missing status, all four accepted
  statuses, atom acceptance, unsupported atom/tuple/nil encoding, invalidation
  overrides, and existing invalid-reason preservation.
- Formatting and diff checks passed, and no temporary proof files remain.
- Static ownership checks confirmed status normalization and invalidation have
  one production implementation behind the preserved facade seam.
- Runtime xref confirmed `cadence_import.ex` is the direct consumer of
  `manifest_row_normalization.ex`.
- Bounded local review found no accepted-status ownership, encoding, overwrite,
  reason-preservation, row-shape, aggregation-order, or schema changes.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport manifest-row status normalization extraction, selected in
`805bc211` and implemented in `2c195242`. `cadence_import.ex` moved from 3,119
to 3,097 lines; the extracted owner is 34 lines.

Next candidate:
Extract central manifest assembly after row-status normalization has one
production owner.

Blocked:
No.

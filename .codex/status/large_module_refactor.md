# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport manifest-row status normalization extraction.

Status:
Selected; implementation has not started.

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
Pending: focused accepted/unsupported status baselines, exact normalization
decision matrix, strict compile, all combined CadenceImport tests, schema
contracts, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport operational-readiness context extraction, selected in `a130e6f5`
and implemented in `3da7bbea`. `cadence_import.ex` moved from 3,225 to 3,119
lines; the extracted owner is 64 lines.

Next candidate:
Extract central manifest assembly after row-status normalization has one
production owner.

Blocked:
No.

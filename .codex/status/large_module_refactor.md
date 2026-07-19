# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport manifest-map normalization extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract top-level nil compaction and nonempty-map normalization into
`OrbitalDynamics.CadenceImport.ManifestMapNormalization`. Preserve the facade's
existing `compact_map/1` and `non_empty_map/1` callback seams as delegates for
all row builders.

Selection evidence:
- `cadence_import.ex` is now 3,341 lines.
- The selected tail family is small but is shared by manifest construction and
  nearly every extracted row builder through stable callbacks.
- The family has one responsibility: remove top-level nil map entries and map
  empty/non-map context values to nil without recursively altering values.
- Row construction, nested normalization, schemas, ordering, and manifest
  dispatch remain outside the boundary.
- This ownership seam enables the next large review-summary context extraction
  without duplicating compaction behavior.

Verification:
Pending: focused representative row/manifest baselines, exact map-normalization
decision matrix, strict compile, all combined CadenceImport tests, schema
contracts, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport manifest-contract diagnostic extraction, selected in `1a983a0c`
and implemented in `580eb142`. `cadence_import.ex` moved from 3,349 to 3,341
lines; the extracted owner is 20 lines.

Next candidate:
Extract review-summary context selection after manifest-map normalization has
one production owner.

Blocked:
No.

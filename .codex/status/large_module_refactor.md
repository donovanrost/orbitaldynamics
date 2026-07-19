# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport manifest-map normalization extraction.

Status:
Completed and published.

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
- Strict test compile passed with 3,816 files and warnings as errors.
- Three focused representative row/manifest tests passed with 69 excluded.
- All combined CadenceImport tests passed: 96 tests.
- CadenceImport schema contracts passed: 4 tests.
- An 8-case direct decision matrix covered top-level nil removal, preservation of
  false/zero/empty and nested values, key-value enumerables, nonempty maps,
  empty maps, and non-map inputs.
- Formatting and diff checks passed, and no temporary proof files remain.
- Static ownership checks confirmed both normalization policies have one
  production implementation behind the preserved facade callback seams.
- Runtime xref confirmed `cadence_import.ex` is the direct consumer of
  `manifest_map_normalization.ex`.
- Bounded local review found no callback, recursion, preservation, empty-map,
  row-shape, or schema changes.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport manifest-map normalization extraction, selected in `ac1a8ab3` and
implemented in `a28108f9`. `cadence_import.ex` moved from 3,341 to 3,337 lines;
the extracted owner is 12 lines.

Next candidate:
Extract review-summary context selection after manifest-map normalization has
one production owner.

Blocked:
No.

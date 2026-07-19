# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport review-row metadata extraction.

Status:
Completed and published.

Selected boundary:
Extract source review-action fallback, nonempty review queue propagation, and
generic review activity-context fallback into
`OrbitalDynamics.CadenceImport.ReviewRowMetadata`. Preserve the facade's
existing three private seams as delegates for row builders.

Selection evidence:
- `cadence_import.ex` is now 3,087 lines.
- The selected helpers are shared across row builders and encode one
  responsibility: preserve source review metadata through ordered fallbacks
  while suppressing nil/empty queue values.
- Manifest assembly, status normalization, row-specific construction,
  capability metadata, schemas, and ordering remain outside the boundary.

Verification:
- Strict test compile passed with 3,821 files and warnings as errors.
- Two focused queue/activity-context tests passed with 70 excluded.
- All combined CadenceImport tests passed: 96 tests.
- CadenceImport schema contracts passed: 4 tests.
- A 7-case direct matrix covered action precedence/fallback, both queue fields,
  nil/empty queue suppression, and import/activity/source/replacement context
  fallback order.
- Formatting and diff checks passed, and no temporary proof files remain.
- Static ownership checks confirmed all three metadata policies have one
  production implementation behind the preserved facade seams.
- Runtime xref confirmed `cadence_import.ex` is the direct consumer of
  `review_row_metadata.ex`.
- Bounded local review found no fallback order, queue suppression, overwrite,
  row-shape, manifest-shape, or schema changes.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport review-row metadata extraction, selected in `ff22d4ee` and
implemented in `8affcbb2`. `cadence_import.ex` moved from 3,087 to 3,078 lines;
the extracted owner is 21 lines.

Next candidate:
Extract central manifest assembly after statistics have one production owner.

Blocked:
No.

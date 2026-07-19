# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport review-summary context extraction.

Status:
Completed and published.

Selected boundary:
Extract review-package summary field selection and provenance
`run_input_sources` promotion into
`OrbitalDynamics.CadenceImport.ReviewSummaryContext`. Preserve the facade's
existing `review_summary_context/1` seam as a delegate and reuse the extracted
manifest-map normalizer for final nil compaction.

Selection evidence:
- `cadence_import.ex` is now 3,337 lines.
- The selected contiguous family spans about 112 lines, primarily an ordered
  allowlist of readiness, station-pressure, capacity-pack, provider-reservation,
  and reservation-expiration summary fields.
- The family has one responsibility: select review-package summary context,
  conditionally promote nonempty provenance run-input sources, and compact nil
  values.
- Manifest assembly, row normalization, capability metadata, schemas, ordering,
  and review-row construction remain outside the boundary.

Verification:
- Strict test compile passed with 3,817 files and warnings as errors.
- Three focused readiness, candidate-refresh, and provider-reservation summary
  tests passed with 72 excluded.
- All combined CadenceImport tests passed: 96 tests.
- CadenceImport schema contracts passed: 4 tests.
- An AST-derived proof against selection commit `18611476` confirmed exact
  ordered equality for all 99 review-summary fields.
- Five direct behavior cases covered all-field retention, ignored-field removal,
  nil compaction, nonempty run-input-source promotion, and empty/non-map
  promotion suppression.
- Formatting and diff checks passed, and no temporary proof files remain.
- Static ownership checks confirmed field selection and run-input-source
  promotion have one production implementation behind the preserved facade
  seam.
- Runtime xref confirmed `cadence_import.ex` is the direct consumer of
  `review_summary_context.ex`.
- Bounded local review found no field membership/order, promotion, compaction,
  context shape, manifest assembly, or schema changes.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport review-summary context extraction, selected in `18611476` and
implemented in `19e4312d`. `cadence_import.ex` moved from 3,337 to 3,225 lines;
the extracted owner is 122 lines.

Next candidate:
Return to manifest assembly or remaining row-dispatch policy after review-summary
context has one production owner.

Blocked:
No.

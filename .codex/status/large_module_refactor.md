# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport review-summary context extraction.

Status:
Selected; implementation has not started.

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
Pending: focused readiness/capacity/provider-summary baselines, AST-derived
ordered allowlist proof, exact promotion/compaction matrix, strict compile, all
combined CadenceImport tests, schema contracts, static single ownership,
runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport manifest-map normalization extraction, selected in `ac1a8ab3` and
implemented in `a28108f9`. `cadence_import.ex` moved from 3,341 to 3,337 lines;
the extracted owner is 12 lines.

Next candidate:
Return to manifest assembly or remaining row-dispatch policy after review-summary
context has one production owner.

Blocked:
No.

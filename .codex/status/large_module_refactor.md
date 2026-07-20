# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema study-result metadata validation context extraction.

Status:
Selected; implementation pending.

Selected boundary:
Add a `StudyResultValidation` owner-default entry point for
`study_benchmark.v1` and `manifest_field_reference.v1`. Derive requirements
from `StudyResultRegistryContracts`, route both direct `Schema` clauses, and
keep both artifact-specific contract APIs unchanged.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,851 lines; the other
  targeted public facades are now 164 to 524 lines.
- The two adjacent clauses repeat required-field setup and form the non-recursive
  leaf subset of `StudyResultRegistryContracts`.
- `StudyBenchmarkContracts` and `ManifestFieldReferenceContracts` own all
  selected artifact-specific validation.
- Neither selected route needs callbacks, recursive `Schema` lookup, model
  limits, or facade-local context.
- `result_artifact.v1` remains out of scope because its validation requires a
  nested execution-report callback and therefore has a distinct boundary.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, validation ordering and paths, public `Schema`
APIs, validation results, and checked-in exports must remain unchanged.

Last completed slice:
Schema validation-policy artifact context extraction, selected in `0b0162c1`
and implemented in `5b893e8e`.
`schema.ex` moved from 4,860 to 4,851 lines.

Next candidate:
Implement and verify the selected study-result metadata context, then re-rank
the remaining Schema responsibility clusters.

Blocked:
No.

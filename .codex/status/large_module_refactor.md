# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport manifest statistics extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract per-field row frequency aggregation and known-limit string rendering
into `OrbitalDynamics.CadenceImport.ManifestStatistics`. Preserve the facade's
existing `count_by/2` and `model_limits/0` seams as delegates and pass the
existing capability map into the limit renderer.

Selection evidence:
- `cadence_import.ex` is now 3,097 lines.
- The selected aggregation family is shared by six central manifest summary
  fields plus model-limit output.
- The family has one responsibility: render deterministic row-frequency maps
  and string-valued known limits without taking ownership of capability data.
- Manifest assembly, row normalization, capability construction, row builders,
  schemas, and ordering outside frequency keys remain outside the boundary.

Verification:
Pending: focused capability/manifest baselines, exact aggregation/limit matrix,
strict compile, all combined CadenceImport tests, schema contracts, static
single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport manifest-row status normalization extraction, selected in
`805bc211` and implemented in `2c195242`. `cadence_import.ex` moved from 3,119
to 3,097 lines; the extracted owner is 34 lines.

Next candidate:
Extract central manifest assembly after statistics have one production owner.

Blocked:
No.

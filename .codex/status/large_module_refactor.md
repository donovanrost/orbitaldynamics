# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport review-row metadata extraction.

Status:
Selected; implementation has not started.

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
Pending: focused queue/activity-context baselines, exact fallback matrix, strict
compile, all combined CadenceImport tests, schema contracts, static single
ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport manifest statistics extraction, selected in `155ae778` and
implemented in `e3c402cd`. `cadence_import.ex` moved from 3,097 to 3,087 lines;
the extracted owner is 18 lines.

Next candidate:
Extract central manifest assembly after statistics have one production owner.

Blocked:
No.

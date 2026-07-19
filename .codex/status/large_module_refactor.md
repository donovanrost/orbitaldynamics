# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport import-readiness policy extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract Cadence-import presence detection and adapter import-status resolution
into `OrbitalDynamics.CadenceImport.ImportReadinessPolicy`. Move the
`cadence_import_present?/2` and `adapter_import_status/2` policies plus their
private nonempty-string predicate while preserving the two existing private
callback seams as delegates.

Selection evidence:
- `cadence_import.ex` is now 3,573 lines.
- The selected policy family spans about 23 lines and is passed through the
  facade to contact-intent, operational-timeline, generic-review, and other row
  builders as stable callbacks.
- The family has one responsibility: decide whether Cadence import data is
  present and translate source/approval states into the adapter import status.
- Row construction, activity context, review actions, provider normalization,
  schemas, ordering, and manifest construction remain outside the boundary.

Verification:
Pending: focused readiness baselines, exact presence/status decision matrix,
strict compile, all combined CadenceImport tests, schema contracts, static
single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport source-identifier policy extraction, selected in `94797583` and
implemented in `fa5fad26`. `cadence_import.ex` moved from 3,604 to 3,573 lines;
the extracted owner is 52 lines.

Next candidate:
Return to the remaining CadenceImport row-building or manifest-routing helpers
after import readiness has one production policy owner.

Blocked:
No.

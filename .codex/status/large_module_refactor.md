# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport timeline source-identifier policy extension.

Status:
Selected; implementation has not started.

Selected boundary:
Move the duplicate timeline activity-state and preservation-status source-ID
fallback chains into the existing
`OrbitalDynamics.CadenceImport.SourceIdentifierPolicy`. Preserve both facade
seams as delegates and resolve the existing option override before entering the
policy owner.

Selection evidence:
- `cadence_import.ex` is now 2,813 lines.
- The selected two helpers are identical ordered fallback chains and belong with
  the existing source/manifest identifier policy.
- The family has one responsibility: choose option, ID, source, timeline,
  activity, then explicit fallback identity in that order.
- Option parsing, manifest dispatch, row building, schemas, and ordering remain
  outside the boundary.

Verification:
Pending: focused timeline state/preservation baselines, exact fallback matrix,
strict compile, all combined CadenceImport tests, schema contracts, static
single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport strategy-review orchestration extraction, selected in `4ace6e1e`
and implemented in `4eb8beeb`. `cadence_import.ex` moved from 2,825 to 2,813
lines; the extracted owner is 25 lines.

Next candidate:
Return to remaining review-package or row dispatch after timeline identity
fallback has one production owner.

Blocked:
No.

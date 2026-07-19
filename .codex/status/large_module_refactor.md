# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport candidate-diff field policy extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract candidate-diff changed-field derivation and count normalization into
`OrbitalDynamics.CadenceImport.CandidateDiffFields`. Preserve the facade's
existing derivation and count callback seams as delegates; keep semantic-change
detail field collection private to the new owner.

Selection evidence:
- `cadence_import.ex` is now 3,361 lines.
- The selected contiguous policy family spans about 18 lines and is shared by
  candidate-diff and approval-requirement row builders through stable callbacks.
- The family has one responsibility: combine explicit and semantic-detail
  changed fields, retain binary names, deduplicate/sort them, and omit the count
  when the resulting list is empty.
- Dispatch, row construction, review actions, map compaction, schemas, and
  manifest construction remain outside the boundary.

Verification:
Pending: focused candidate-refresh and approval-requirement baselines, exact
field/count decision matrix, strict compile, all combined CadenceImport tests,
schema contracts, static single ownership, runtime xref, and bounded review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport approval-context selection policy extraction, selected in
`a0ced38d` and implemented in `6b3411ab`. `cadence_import.ex` moved from 3,407
to 3,361 lines; the extracted owner is 64 lines.

Next candidate:
Return to the remaining CadenceImport row-building or manifest-routing helpers
after candidate-diff field derivation has one production owner.

Blocked:
No.

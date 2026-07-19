# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport approval-context selection policy extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Extract approval-requirement, preferred rule-match, and preferred escalation
selection into `OrbitalDynamics.CadenceImport.ApprovalContextPolicy`. Preserve
the facade's existing three callback seams as delegates; keep approval
classification, rule-match filtering, and escalation-context detection private
to the new owner.

Selection evidence:
- `cadence_import.ex` is now 3,407 lines.
- The selected contiguous policy family spans about 55 lines and is shared by
  contact-intent, suppression, and approval-requirement row builders through
  stable callbacks.
- The family has one responsibility: normalize and choose the most relevant
  approval requirement, rule match, and escalation context with current
  classification/rule-ID precedence.
- Dispatch, row construction, review actions, map compaction, schemas, ordering
  outside candidate selection, and manifest construction remain outside the
  boundary.

Verification:
Pending: focused contact-intent, approval-requirement, and suppression baselines,
exact selection decision matrix, strict compile, all combined CadenceImport
tests, schema contracts, static single ownership, runtime xref, and bounded
review.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport station-calendar context field catalog extraction, selected in
`f2d6c001` and implemented in `e7fd5299`. `cadence_import.ex` moved from 3,428
to 3,407 lines; the extracted owner is 28 lines.

Next candidate:
Return to the remaining CadenceImport row-building or manifest-routing helpers
after approval-context selection has one production owner.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport approval-context selection policy extraction.

Status:
Completed and published.

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
- Strict test compile passed with 3,813 files and warnings as errors.
- Three focused contact-intent, approval-requirement, and suppression tests
  passed with 69 excluded.
- All combined CadenceImport tests passed: 96 tests.
- CadenceImport schema contracts passed: 4 tests.
- An 11-case direct decision matrix covered requirement filtering and
  normalization, approval-status/classification precedence, first-map fallback,
  row/source rule-ID matching, escalation ordering, contextual fallback, and
  invalid inputs.
- Formatting and diff checks passed, and no temporary proof files remain.
- Static ownership checks confirmed the selection chain has one production
  implementation behind the three preserved facade callback seams.
- Runtime xref confirmed `cadence_import.ex` is the direct consumer of
  `approval_context_policy.ex`.
- Bounded local review found no callback, normalization, precedence, candidate
  order, fallback, row-shape, or schema changes.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
CadenceImport approval-context selection policy extraction, selected in
`a0ced38d` and implemented in `6b3411ab`. `cadence_import.ex` moved from 3,407
to 3,361 lines; the extracted owner is 64 lines.

Next candidate:
Return to the remaining CadenceImport row-building or manifest-routing helpers
after approval-context selection has one production owner.

Blocked:
No.

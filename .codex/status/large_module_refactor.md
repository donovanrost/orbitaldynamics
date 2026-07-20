# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactAllocation returned-allocation extraction.

Status:
Completed and pushed in `cd708fc8`.

Selected boundary:
Extract contention recommendation lookup maps, allocation-row ordering,
effective allocation status, allocated-row selection, returned contact lookup,
and returned allocation context projection into
`OrbitalDynamics.Communications.ContactAllocation.ReturnedAllocation`.
Preserve all ContactAllocation and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `communications/contact_allocation.ex` at 1,804 lines,
  the
  largest ordinary eligible facade.
- ContactAllocation already delegates nine focused responsibilities, while
  resolution lookup and returned-allocation projection remain inline at lines
  1,433-1,530.
- The selected block has one responsibility: turn finalized allocation rows
  back into the public returned-contact view.
- Allocation report construction, blocked/base row projection, capacity
  packing, validation, approvals, summaries, and all public contracts remain
  outside the boundary.
- Exact recommendation lookup overwrite behavior, row ordering, effective
  status precedence, original-contact lookup, projected fields,
  provider-counteroffer context, omission behavior, and error behavior must
  remain unchanged.

Implementation:
- Added `OrbitalDynamics.Communications.ContactAllocation.ReturnedAllocation`
  as the owner of recommendation lookup maps, row ordering, effective status,
  allocated-row selection, original-contact lookup, and returned allocation
  context.
- Wired the allocation orchestration directly to the owner while preserving
  ContactAllocation and root public APIs.
- Kept row/report construction, capacity packing, validation, approvals, and
  summaries in their existing owners.
- `contact_allocation.ex` moved from 1,804 to 1,707 lines; the new owner is 110
  lines.

Verification:
- Strict focused baseline passed all 70 ContactAllocation tests.
- Exact old/new public parity passed for four deterministic allocation results:
  priority-aware selected/deferred contention with counteroffer context,
  non-overlapping row ordering, reservation/capacity context, and empty input.
- Post-extraction focused and adjacent allocation-schema verification passed
  all 79 tests.
- Static checks confirm returned-allocation lookup/projection helpers left the
  facade; xref reports only ContactAllocation as a runtime caller.
- Strict warning-clean forced compile passed for 4,007 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
ContactAllocation returned-allocation extraction, selected in `e7a28cf9` and
implemented in `cd708fc8`.
`contact_allocation.ex` moved from 1,804 to 1,707 lines; the dedicated
ReturnedAllocation owner is 110 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `timeline_feedback.ex` is now the largest ordinary eligible facade
at 1,797 lines, followed by ResourceProjection and ContactIntent.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactAllocation allocation-row projection extraction.

Status:
Completed and pushed in `1b9d3a71`.

Selected boundary:
Extract selected/deferred/available allocation-row construction, shared base-row
evidence projection, provider counteroffer/resource suppression context, and
contention allocation reasons into
`OrbitalDynamics.Communications.ContactAllocation.AllocationRow`.
Preserve all ContactAllocation and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `communications/contact_allocation.ex` at 1,707 lines,
  the
  largest ordinary eligible facade.
- ContactAllocation already delegates ten focused responsibilities, while
  allocation-row decision and base evidence projection remain inline at lines
  1,244-1,432 with their value-routing helpers.
- The selected block has one responsibility: turn a normalized contact and
  contention recommendation into the deterministic allocation row consumed by
  capacity packing, policy classification, blocked-row projection, and report
  assembly.
- Allocation orchestration, validation/filtering, capacity packing, approval
  policy, summaries, returned contacts, and all public contracts remain outside
  the boundary.
- Exact decision precedence, IDs, evidence fields, feedback/provider-result
  normalization, station-calendar list/count normalization, context merges,
  compaction, output, and error behavior must remain unchanged.

Implementation:
- Added `OrbitalDynamics.Communications.ContactAllocation.AllocationRow` as the
  owner of selected/deferred/available row decisions, shared base-row evidence,
  provider counteroffer/resource suppression context, provider-result value
  routing, and contention allocation reasons.
- Wired allocation and blocked-row construction through thin owner delegates
  while preserving ContactAllocation and root public APIs.
- Kept orchestration, validation/filtering, capacity packing, approval policy,
  summaries, and returned-contact handling outside the boundary.
- `contact_allocation.ex` moved from 1,707 to 1,413 lines; the new owner is 314
  lines.

Verification:
- Strict focused baseline passed all 70 ContactAllocation tests.
- Exact old/new public parity passed for four deterministic allocation results:
  rich contention/base evidence, duplicate contacts, invalid contacts, and empty
  input.
- Post-extraction focused and adjacent allocation/schema verification passed all
  79 tests.
- The adjacent suite additionally verified exact direction-only contact type
  policy after correcting the owner to preserve the original fallback.
- Static checks confirm allocation-row value/projection helpers left the facade;
  xref reports only ContactAllocation as a runtime caller.
- Strict warning-clean forced compile passed for 4,013 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
ContactAllocation allocation-row projection extraction, selected in `ea5cd7ae`
and implemented in `1b9d3a71`.
`communications/contact_allocation.ex` moved from 1,707 to 1,413 lines; the
dedicated AllocationRow owner is 314 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `operational_readiness.ex` is now the largest ordinary eligible
facade at 1,686 lines, followed by StationCalendar and ContactContention.

Blocked:
No.

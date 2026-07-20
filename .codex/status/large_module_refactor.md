# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactAllocation allocation-row projection extraction.

Status:
Selected; strict focused baseline pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness gate-summary extraction, selected in `dfa512f8` and
implemented in `fef750c5`.
`operational_readiness.ex` moved from 1,768 to 1,686 lines; the dedicated
GateSummary owner is 86 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `communications/contact_allocation.ex` is now the largest ordinary
eligible facade at 1,707 lines, followed by OperationalReadiness and
StationCalendar.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
OperationalReadiness execution-boundary summary extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract execution-boundary summary construction and import-classification
boundary mapping into
`OrbitalDynamics.OperationalReadiness.ExecutionBoundarySummary`.
Preserve all OperationalReadiness and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `operational_readiness.ex` at 1,686 lines, the
  largest ordinary eligible facade.
- OperationalReadiness already delegates gate and specialized quality summary
  responsibilities, while execution-boundary projection remains inline at lines
  464-514.
- The selected block has one responsibility: expose import eligibility and
  explicit no-execution/no-write/no-authority boundaries from readiness gates.
- Readiness report classification, import eligibility, gate routing,
  quality-gate rows, evidence collection, and all public contracts remain
  outside the boundary.
- Exact operational-mode selection, gate counts, non-passed ordering,
  classification mapping, omission behavior, assumptions, model limits, public
  output, and error behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

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

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema resource-filter validation routing cleanup.

Status:
Selected; implementation not started.

Selected boundary:
Complete the resource-filter portion of the existing
`OrbitalDynamics.Schema.ResourceValidation` extraction by routing contract
clauses and callback tables directly to that owner and removing four facade
pass-through wrappers.
Preserve all `OrbitalDynamics.Schema` public facades and validation output.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,612 lines.
- Resource-filter validation already has a focused owner, but the facade
  retains four pure one-hop wrappers referenced by report/summary contract
  clauses and campaign/candidate callback tables.
- The selected code has one responsibility: route optional/resource-filter
  reports, suppressed candidates, and invalid resource inputs to the owner.
- Resource-projection adapters remain in the facade because they inject policy
  and stable-ID callbacks. Callback-table composition, other
  artifact-family validation, JSON Schema generation, and all public routing
  remain outside the boundary.
- Exact issue ordering, paths, messages, malformed-input behavior, callback
  wiring, public validation results, and schema exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema contact-report validation routing cleanup, selected in `b947a636` and
implemented in `f318e290`.
`schema.ex` moved from 6,622 to 6,612 lines by completing routing to the
existing ContactReportValidation owner.

Next candidate:
After this slice, re-rank the remaining schema wrapper clusters while
preserving dependency-injecting resource-projection adapters.

Blocked:
No.

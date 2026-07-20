# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-report validation routing cleanup.

Status:
Selected; implementation not started.

Selected boundary:
Complete the existing `OrbitalDynamics.Schema.ContactReportValidation`
extraction by routing contract clauses and callback tables directly to that
owner and removing five facade pass-through wrappers.
Preserve all `OrbitalDynamics.Schema` public facades and validation output.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,622 lines.
- Contact filter/contention validation already has a focused owner, but the
  facade retains five pure one-hop wrappers referenced by contract clauses and
  campaign/candidate callback tables.
- The selected code has one responsibility: route contact-filter reports and
  optional contention/resolution reports to the existing owner.
- Callback-table composition, contact-allocation validation, other
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
Schema timeline-context validation routing cleanup, selected in `88bd2853` and
implemented in `d9d05131`.
`schema.ex` moved from 6,640 to 6,622 lines by completing routing to the
existing TimelineContextValidation owner.

Next candidate:
After this slice, re-rank the remaining schema wrapper clusters. Keep
dependency-injecting transition/source-status adapters in the facade.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema source-evidence validation/status routing cleanup.

Status:
Selected; implementation not started.

Selected boundary:
Make `OrbitalDynamics.Schema.SourceEvidenceValidation` authoritative for
freshness/schema-validation status enums, route JSON Schema evidence builders
and callback tables through that owner, and remove six facade helpers.
Preserve all `OrbitalDynamics.Schema` public facades, JSON Schema output, and
validation behavior.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,580 lines.
- Source-evidence validation already has a focused owner, but freshness and
  schema-validation enums remain private in the facade while four callback
  wrappers split validation routing across both modules.
- The selected code has one responsibility: own source-evidence status enums
  and validate source fields plus freshness/schema/execution status matches.
- JSON Schema evidence builders continue to receive the exact same enum
  values. Callback-table composition, other
  artifact-family validation, JSON Schema generation, and all public routing
  remain outside the boundary.
- Exact enum ordering, issue ordering, paths, messages, callback wiring,
  public validation results, and schema exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema station-reservation validation routing cleanup, selected in `d4db8b09`
and implemented in `bc5ce973`.
`schema.ex` moved from 6,602 to 6,580 lines by completing routing to the
existing StationReservationValidation owner.

Next candidate:
After this slice, re-rank the remaining schema responsibility clusters while
preserving dependency-injecting adapters.

Blocked:
No.

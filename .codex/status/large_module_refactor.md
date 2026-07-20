# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema relay data-path owner completion.

Status:
Selected; implementation pending.

Selected boundary:
Extend `LinkCapacityValidation` to own registry-backed validation for
`relay_data_path_summary.v1`. Route the direct `Schema` clause through the
ground-network capacity owner while preserving required-field setup followed
by `RelayDataPathSummaryContracts.validate_summary/3`.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,728 lines; the other
  targeted public facades are now 164 to 524 lines.
- The relay summary is produced from link-capacity/contact routing evidence and
  is adjacent to the existing link-capacity report/summary owner.
- `RelayDataPathRegistryContracts` and `RelayDataPathSummaryContracts` already
  provide the exact setup and validator.
- No route needs recursive `Schema` lookup.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, validation ordering and paths, public `Schema`
and existing `LinkCapacityValidation` APIs, validation results, and checked-in
exports must remain unchanged.

Last completed slice:
Schema candidate-activity owner completion, selected in `313e38cf` and
implemented in `23cf1b4e`. `schema.ex` moved from 4,730 to 4,728 lines.

Next candidate:
Implement and verify the selected relay data-path owner completion, then
re-rank the remaining Schema responsibility clusters.

Blocked:
No.

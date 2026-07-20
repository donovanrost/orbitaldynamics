# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema link-capacity owner completion.

Status:
Selected; implementation pending.

Selected boundary:
Add a registry-backed `LinkCapacityValidation.validate_summary/3` entry point
for `link_capacity_summary.v1` and route its direct `Schema` clause through the
existing owner. Preserve the existing report and optional-report APIs.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,773 lines; the other
  targeted public facades are now 164 to 524 lines.
- `link_capacity_report.v1` already routes through `LinkCapacityValidation`.
- `link_capacity_summary.v1` is the only other
  `LinkCapacityRegistryContracts` member and repeats registry-required setup in
  the facade.
- `LinkCapacitySummaryContracts` owns all summary-specific validation.
- No route needs recursive `Schema` lookup.
- `relay_data_path_summary.v1` remains out of scope because it belongs to the
  distinct `RelayDataPathRegistryContracts` family.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, validation ordering and paths, public `Schema`
and existing `LinkCapacityValidation` APIs, validation results, and checked-in
exports must remain unchanged.

Last completed slice:
Schema contact-report owner routing extraction, selected in `7781b44c` and
implemented in `902d27d5`.
`schema.ex` moved from 4,787 to 4,773 lines.

Next candidate:
Implement and verify the selected link-capacity owner completion, then re-rank
the remaining Schema responsibility clusters.

Blocked:
No.

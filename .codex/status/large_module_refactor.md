# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity-resource context extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Move activity resource-state context construction into a dedicated module.
Keep one private Timeline facade for its two coordinator consumers and route
field, numeric, boolean, and compaction dependencies directly.

Selection evidence:
- The builder owns resource provenance/trust/blocking evidence; fuel, power,
  storage, and downlink margins; battery capacity/use/generation/state; four
  availability/degraded booleans; mode; incompatible/suppressed activity types.
- Its two consumers are the operational row and valid activity-context
  coordinators.
- Direct existing policies satisfy the boundary without Timeline callbacks.
- The extraction should materially reduce the current 5,623-line Timeline.
- Precondition, throughput, link, orientation, thermal, product, public API,
  and schema remain outside the boundary.

Verification:
Pending: focused baseline, implementation, strict compile, focused/full tests,
contracts, structural/static checks, and independent review.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity-orientation context extraction, initially selected in
`2179a76d`, corrected in `46dbabb9`, implemented in `65316388`, and handed off
in `e8131ffa`.

Next candidate:
Continue remapping the reduced Timeline facade.

Blocked:
No.

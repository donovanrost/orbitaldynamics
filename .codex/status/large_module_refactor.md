# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity-link context extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Move activity link-profile and link-quality context construction into a
dedicated module. Keep one private Timeline facade for its two coordinator
consumers and route scalar, numeric, boolean, and compaction dependencies
directly.

Selection evidence:
- The builder owns protocol/band/modulation/coding/polarization; planned and
  actual rate variants; delivered/received rates; duration variants; margin,
  SNR, Eb/No, error/loss rates; carrier/symbol locks; quality status.
- Its two consumers are the operational row and valid activity-context
  coordinators.
- Direct existing policies satisfy the boundary without Timeline callbacks.
- The extraction should materially reduce the current 5,585-line Timeline.
- Throughput, precondition, execution uncertainty, command window, resource,
  orientation, public API, and schema remain outside the boundary.

Verification:
Pending: focused baseline, implementation, strict compile, focused/full tests,
contracts, structural/static checks, and independent review.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity-resource context extraction, selected in `45680c40`,
implemented in `d4ba542c`, and handed off in `b3901475`.

Next candidate:
Continue remapping the reduced Timeline facade.

Blocked:
No.

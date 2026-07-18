# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity command-authority context extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Move command-authority context construction into one dedicated module. Keep a
private Timeline facade for its two coordinator consumers and route scalar,
boolean, and compaction dependencies directly through existing policies.

Selection evidence:
- The builder owns command authority status, required authority, command safety
  status, command authorization, and command safety confirmation aliases.
- It has exactly two consumers: operational-row and valid-context assembly.
- Direct existing policies satisfy the boundary without Timeline callbacks.
- The extraction should reduce the current 5,512-line Timeline while preserving
  the private coordinator seam.
- Command windows, feedback outcomes, lifecycle decisions, broad context
  coordination, public API, and schema remain outside the boundary.

Verification:
Pending: focused baseline, implementation, strict compile, focused/full tests,
contracts, structural/static checks, and independent review.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity-observation evidence context extraction, selected in
`ca3f14a2`, corrected in `ff38e55c`, and implemented in `c290eabc`.

Next candidate:
Continue remapping the reduced Timeline facade.

Blocked:
No.

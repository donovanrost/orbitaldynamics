# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity scheduling-coordinate context extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Move activity timing/target and source-window context construction into one
dedicated scheduling-coordinate module. Keep two private Timeline facades for
their valid-context consumers and route timing, source-window identity, and
compaction directly through existing policies. Remove the shared
`activity_duration_s/1` Timeline facade because strict compile confirmed the
moved timing builder owned its only remaining caller.

Selection evidence:
- Timing owns start, end, derived/explicit duration, and target identity.
- Source-window context owns normalized source-window ID and type.
- Each builder has exactly one consumer in valid activity-context assembly.
- The initial strict compile proved `activity_duration_s/1` became unused after
  the move; repo search confirmed start/end and source-window facades still
  serve row and identity paths.
- Direct existing policies satisfy the boundary without Timeline callbacks.
- The extraction should reduce the current 5,343-line Timeline while preserving
  both private coordinator seams.
- General timing/identity facades, source-window normalization, scheduling
  decisions, broad context coordination, public API, and schema remain outside
  the boundary.

Verification:
Pending: focused baseline, implementation, strict compile, focused/full tests,
contracts, structural/static checks, and independent review.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity relationship context extraction, selected in `7a910e0c`,
corrected in `af7fcfff`, and implemented in `2c33add2`.

Next candidate:
Continue remapping the reduced Timeline facade.

Blocked:
No.

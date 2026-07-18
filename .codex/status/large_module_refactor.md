# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity lifecycle context extraction.

Status:
Selected; implementation has not started.

Selected boundary:
Move conditional activity lifecycle context construction into one dedicated
module. Keep one private Timeline facade for the valid-context consumer and
route status and approval-status normalization directly through the existing
lifecycle and artifact-value policies.

Selection evidence:
- The builder conditionally emits status and approval status only when the
  activity or its metadata explicitly carries the corresponding field.
- Existing lifecycle normalization preserves defaults and provider aliases,
  while the context-specific presence check prevents implicit defaults from
  appearing in the reusable context.
- The builder has exactly one consumer in valid activity-context assembly.
- Direct existing policies satisfy the boundary without Timeline callbacks.
- The extraction should reduce the current 5,408-line Timeline while preserving
  the private coordinator seam.
- General lifecycle state normalization, transition decisions, timing, command
  windows, broad context coordination, public API, and schema remain outside the
  boundary.

Verification:
Pending: focused baseline, implementation, strict compile, focused/full tests,
contracts, structural/static checks, and independent review.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity operational-hint context extraction, selected in `37156e81`,
corrected in `d5b82292`, and implemented in `3f72fc39`.

Next candidate:
Continue remapping the reduced Timeline facade.

Blocked:
No.

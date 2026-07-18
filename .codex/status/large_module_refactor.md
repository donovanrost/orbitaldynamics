# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline operational row-classification policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move contact-row and command-row classification into
`Timeline.OperationalRowClassificationPolicy`. `Timeline` retains both public
API entry points and passes its command/health activity types and command
directions explicitly; operational report assembly remains unchanged.

Why this slice:
The 6,262-line Timeline facade still owns two exclusive public classification
bodies used by operational report counts. Moving their policy bodies isolates
exact type/direction membership and ground-station fallback while preserving
the public facade and report coordinator.

Planned proof:
- Focused general operational report, station-ID-only contact, and inferred
  provider contact examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for both moved definitions after normalizing only
  facade/policy names and explicit list arguments.
- Format, diff, whitespace, ownership, exactly-two-public-facade, unchanged
  Timeline public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline invalid activity-input row filtering, selected in `c369cc24` and
implemented in `3a133522`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.

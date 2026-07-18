# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline operational row-classification policy extraction.

Status:
Implemented, verified, independently reviewed, committed, and pushed.

Completed boundary:
Moved contact-row and command-row classification into the 13-line
`Timeline.OperationalRowClassificationPolicy`. The 6,264-line `Timeline`
retains both public API entry points and passes classification lists explicitly;
operational report assembly remains unchanged.

Published commits:
Selected in `f6d58e54` and implemented in `3a689cf2`.

Verification:
- Strict warnings-as-errors compile passed across 3,781 files.
- Three focused general operational report, station-ID-only contact, and
  inferred provider contact examples passed.
- Full Timeline suite passed with 127 examples; Timeline schema-contract suites
  passed with 36 examples.
- Canonical AST equivalence passed for both public classifier bodies after
  normalizing only policy names and list arguments.
- Format, diff, whitespace, ownership, exactly-two-public-facade, unchanged
  Timeline public-definition, and xref checks passed.
- Independent read-only review found no production-code issues.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline operational row-classification policy extraction, selected in
`f6d58e54` and implemented in `3a689cf2`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.

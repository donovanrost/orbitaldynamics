# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline invalid activity-input row filtering extraction.

Status:
Implemented, verified, independently reviewed, committed, and pushed.

Completed boundary:
Moved Timeline's invalid-activity-input row filter into the 153-line
`Timeline.ActivityInputPolicy`. The 6,262-line `Timeline` retains one private
entry point; source/replacement diff assembly and row construction remain
unchanged.

Published commits:
Selected in `c369cc24` and implemented in `3a133522`.

Verification:
- Strict warnings-as-errors compile passed across 3,780 files.
- Three focused invalid operational, invalid source/replacement diff, and valid
  unchanged diff examples passed.
- Full Timeline suite passed with 127 examples; Timeline schema-contract suites
  passed with 36 examples.
- Canonical AST equivalence passed after normalizing only the public/private
  head and facade name.
- Format, diff, whitespace, ownership, exactly-one-facade, unchanged Timeline
  public-definition, and xref checks passed.
- Independent read-only review found no production-code issues; existing input
  issue detection is untouched.

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

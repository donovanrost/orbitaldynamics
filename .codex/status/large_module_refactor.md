# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity-ID encoding policy extraction.

Status:
Implemented, verified, independently reviewed, committed, and pushed.

Completed boundary:
Moved Timeline's remaining activity-ID encoding clause into the existing
56-line `Timeline.ActivityIdentityPolicy`. The 6,252-line `Timeline` retains one
private entry point and passes its artifact value encoder explicitly; other
identity functions and public coordinators remain unchanged.

Published commits:
Selected in `70ce1d8e` and implemented in `24d6193c`.

Verification:
- Strict warnings-as-errors compile passed across 3,776 files.
- Three focused operational-row, reusable transition, and unchanged diff
  examples passed.
- Full Timeline suite passed with 127 examples; Timeline schema-contract suites
  passed with 36 examples.
- Canonical AST equivalence passed after normalizing only the public/private
  head and explicit encoding callback.
- Format, diff, whitespace, ownership, exactly-one-facade, unchanged Timeline
  public-definition, and xref checks passed.
- Independent read-only review found no production-code issues; existing
  identity-policy functions are untouched.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity-ID encoding policy extraction, selected in `70ce1d8e` and
implemented in `24d6193c`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.

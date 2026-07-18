# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline optional activity-input policy extraction.

Status:
Implemented, verified, independently reviewed, committed, and pushed.

Completed boundary:
Moved both optional activity-to-map clauses into the 6-line
`Timeline.OptionalActivityInputPolicy`. The 6,250-line `Timeline` retains one
private entry point and passes its activity conversion function explicitly;
public transition coordinators remain unchanged.

Published commits:
Selected in `cd27ded1` and implemented in `fb8a47fa`.

Verification:
- Strict warnings-as-errors compile passed across 3,776 files.
- Three focused reusable, selected-integrity, and blocked lifecycle transition
  examples passed.
- Full Timeline suite passed with 127 examples; Timeline schema-contract suites
  passed with 36 examples.
- Canonical AST equivalence passed for both moved clauses after normalizing only
  public/private heads, facade name, and the conversion callback.
- Format, diff, whitespace, ownership, exactly-one-facade, unchanged Timeline
  public-definition, and xref checks passed.
- Independent read-only review found no production-code issues.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline optional activity-input policy extraction, selected in `cd27ded1` and
implemented in `fb8a47fa`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.

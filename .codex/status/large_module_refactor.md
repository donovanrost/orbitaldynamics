# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline diff invalid-input context policy extraction.

Status:
Implemented, verified, independently reviewed, committed, and pushed.

Completed boundary:
Moved all three invalid-activity-input diff-context clauses into the 15-line
`Timeline.DiffInvalidInputContextPolicy`. The 6,258-line `Timeline` retains one
private entry point and the diff-row callback remains unchanged; no callback,
constant, coordinator, or schema boundary crosses the extraction.

Published commits:
Selected in `a5faf610` and implemented in `fcf2bd75`.

Verification:
- Strict warnings-as-errors compile passed across 3,770 files.
- Three focused invalid source/replacement, unchanged, and valid changed-row
  diff examples passed.
- Full Timeline suite passed with 127 examples; Timeline schema-contract suites
  passed with 36 examples.
- Canonical AST equivalence passed for all three moved clauses after normalizing
  only public/private heads and facade function names.
- Format, diff, whitespace, ownership, exactly-one-facade, unchanged Timeline
  public-definition, and xref checks passed.
- Independent read-only review found no production-code issues.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline diff invalid-input context policy extraction, selected in `a5faf610`
and implemented in `fcf2bd75`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline diff-comparison policy extraction.

Status:
Implemented, verified, independently reviewed, committed, and pushed.

Completed boundary:
Moved changed-field selection and review-significant field membership into the
12-line `Timeline.DiffFieldSelectionPolicy`. The 6,257-line `Timeline` retains
two private entry points plus both comparison-value clauses; the comparison
callback and full comparison field list cross the boundary explicitly.

Published commits:
Selected in `ed3377ac`, narrowed in `93ec001b`, and implemented in `68e7e332`.

Verification:
- Strict warnings-as-errors compile passed across 3,766 files.
- Four focused changed command, product/latency, throughput, and
  resource-assignment diff examples passed.
- Full Timeline suite passed with 127 examples; Timeline schema-contract suites
  passed with 36 examples.
- Canonical AST equivalence passed for both moved clauses after normalizing
  only heads and explicit callback/list arguments.
- Format, diff, whitespace, ownership, exactly-two-facade, unchanged Timeline
  public-definition, and xref checks passed.
- Independent read-only review found no production-code issues.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline diff-comparison policy extraction, selected in `ed3377ac`, narrowed in
`93ec001b`, and implemented in `68e7e332`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.

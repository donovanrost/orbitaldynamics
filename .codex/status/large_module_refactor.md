# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline terminal-exception classification policy extraction.

Status:
Implemented, verified, independently reviewed, committed, and pushed.

Completed boundary:
Moved the terminal-exception row classifier into the 13-line
`Timeline.TerminalExceptionPolicy`. The 6,224-line `Timeline` retains one
private entry point and passes the terminal-status list and provider-result
failure predicate explicitly; provider-result normalization remains in place.

Published commits:
Selected in `c77b9c61` and implemented in `2712e34d`.

Verification:
- Strict warnings-as-errors compile passed across 3,773 files.
- Three focused terminal-status, provider failure alias, and provider failure
  map examples passed.
- Full Timeline suite passed with 127 examples; Timeline schema-contract suites
  passed with 36 examples.
- Canonical AST equivalence passed after normalizing only the public/private
  head, facade name, terminal-status argument, and callback.
- Format, diff, whitespace, ownership, exactly-one-facade, unchanged Timeline
  public-definition, and xref checks passed.
- Independent read-only review found no production-code issues.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline terminal-exception classification policy extraction, selected in
`c77b9c61` and implemented in `2712e34d`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.

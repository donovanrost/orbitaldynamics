# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity-input normalization flow extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move safe activity conversion, validation dispatch, invalid-row routing, and
valid activity normalization into `Timeline.ActivityInputNormalization`.
`Timeline` retains private `normalize_activity_input/2` and
`activity_input_to_map/2` entry points because the latter is shared across
candidate, lifecycle, diff, and summary paths. Activity conversion, issue
classification, invalid-row construction, and valid normalization are supplied
as callbacks.

Why this slice:
The reduced Timeline facade is 7,507 lines. These four exclusive clauses form a
small but reusable normalization transaction: conversion exceptions become
deterministic invalid rows, validation failures route through the same builder,
and valid inputs retain sequence-aware normalization.

Planned proof:
- Focused Timeline tests for invalid batch input, single invalid normalization,
  and valid identity preservation.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all four moved clauses after normalizing only
  the two facade names and callback boundaries.
- Format, diff, whitespace, ownership, exactly-two-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity-input validation policy extraction, selected in `677f8278`,
implemented in `ea3e2c42`, and handed off in `77d4770a`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing transition
integrity gating and activity normalization.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity-input validation policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move activity input issue precedence plus ID/type/status/approval, nested-shape,
unit-interval, and stable-identity-path validation into
`Timeline.ActivityInputPolicy`. `Timeline` retains one private
`activity_input_issue/1` facade. Status/approval lists and field/path metadata
are supplied as selection data; activity status/approval normalization,
numeric normalization, and stable-ID validation are supplied as callbacks.

Why this slice:
The reduced Timeline facade is 7,619 lines. These 19 exclusive clauses form an
approximately 125-line validation responsibility with no callers outside the
one facade. Keeping the short-circuit issue order together preserves which
invalid reason wins when multiple fields are malformed.

Planned proof:
- Focused Timeline tests for general invalid inputs, unit intervals, unsupported
  approval/status, malformed activity IDs, and malformed identity fields.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all 19 moved clauses after normalizing only the
  facade name and selection-data/callback boundaries.
- Format, diff, whitespace, ownership, exactly-one-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline invalid-activity row extraction, selected in `e586b0f5`, implemented
in `9ee57bb5`, and handed off in `90456b40`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing transition
integrity gating and invalid-input normalization flow.

Blocked:
No.

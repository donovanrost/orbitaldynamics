# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline operational action policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move operational-kind inference, Cadence-import status classification, required
operator-action precedence, and command-review policy into
`Timeline.OperationalActionPolicy`. `Timeline` retains three private entry
points used by row construction. Command directions plus terminal/executed
status lists are supplied as selection data; the seven existing status/import/
lock/provider evidence helpers are supplied as callbacks.

Why this slice:
The reduced Timeline facade is 7,752 lines. This approximately 95-line,
14-clause cluster has one cohesive operational classification responsibility
and is exclusive to normalized row construction. Keeping all precedence
branches together avoids splitting kind/import inference from the action policy
that consumes them.

Planned proof:
- Focused Timeline tests for command authority, kind/import classification,
  malformed Cadence import, conflict/terminal precedence, provider failure, and
  rejected/blocked precedence.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all 14 clauses after normalizing only the three
  facade names and selection-data/callback boundaries.
- Format, diff, whitespace, ownership, exactly-three-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline single-transition decision policy extraction, selected in `e398ffc1`,
implemented in `11b72e46`, and handed off in `0407e6f0`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing transition
integrity gating and Cadence-import validation.

Blocked:
No.

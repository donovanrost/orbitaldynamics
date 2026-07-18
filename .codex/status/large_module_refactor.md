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
Move Cadence-import status classification, required operator-action precedence,
and command-review policy into `Timeline.OperationalActionPolicy`. `Timeline`
retains two private entry points used by row construction. Terminal/executed
status lists are supplied as selection data; the seven existing status/import/
lock/provider evidence helpers are supplied as callbacks. Operational-kind
inference remains Timeline-owned because its command-direction clause uses the
shared compile-time guard list also surfaced by capabilities.

Why this slice:
The reduced Timeline facade is 7,752 lines. This approximately 65-line,
three-clause cluster has one cohesive operational-action responsibility and is
exclusive to normalized row construction. The corrected boundary preserves the
compile-time operational-kind guard without duplicating its shared constant.

Planned proof:
- Focused Timeline tests for command authority, kind/import classification,
  malformed Cadence import, conflict/terminal precedence, provider failure, and
  rejected/blocked precedence.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all three moved clauses after normalizing only
  the two facade names and selection-data/callback boundaries.
- Format, diff, whitespace, ownership, exactly-two-facade, unchanged Timeline
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

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline diff invalid-input context policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move all three invalid-activity-input diff-context clauses into
`Timeline.DiffInvalidInputContextPolicy`. `Timeline` retains one private entry
point and the existing diff-row callback remains unchanged; no callback,
constant, coordinator, or schema boundary crosses the extraction.

Why this slice:
The 6,266-line Timeline facade still owns three exclusive context-shaping
clauses for invalid diff inputs. Moving the complete clause family isolates
prefix interpolation and empty/default behavior without pulling the adjacent
wide dependency context or callback-bearing protection context across the
boundary.

Planned proof:
- Focused invalid source/replacement diff, unchanged public-facade diff, and
  valid changed-row diff examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all three moved clauses after normalizing only
  public/private heads and facade function names.
- Format, diff, whitespace, ownership, exactly-one-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline row-state classification policy extraction, selected in `f609bf27` and
implemented in `88520818`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.

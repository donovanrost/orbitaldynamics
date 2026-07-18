# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline row-state classification policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move approved-row, executed-row, and integrity-review-row predicates into
`Timeline.RowStateClassificationPolicy`. `Timeline` retains three private entry
points and passes the existing executed-status list explicitly. The adjacent
terminal-exception predicate remains because it owns provider-result callbacks.

Why this slice:
The 6,259-line Timeline facade still owns three exclusive scalar row-state
classifiers reused by operational summaries and integrity review routing.
Moving them together isolates their exact membership/equality semantics without
pulling the callback-bearing terminal-exception classifier or report
coordinators across the boundary.

Planned proof:
- Focused approved-row operational report, executed-row terminal report, and
  integrity-review routing examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all three moved clauses after normalizing only
  public/private heads, facade names, and the explicit executed-status argument.
- Format, diff, whitespace, ownership, exactly-three-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline relationship-presence policy extraction, selected in `4cee1cae` and
implemented in `ee9f01a3`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.

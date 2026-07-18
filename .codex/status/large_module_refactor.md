# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline diff-presentation policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move the three diff required-operator-action clauses and two diff reason
clauses into `Timeline.DiffPresentationPolicy`. `Timeline` retains two private
entry points and the existing diff-row callback list remains unchanged; no
callback, constant, or coordinator crosses the new boundary.

Why this slice:
The 6,257-line Timeline facade still owns five exclusive, adjacent presentation
clauses used only through diff-row callbacks. Moving them together isolates
stable action and reason wording without widening the already callback-heavy
`DiffRow` boundary.

Planned proof:
- Focused unchanged public-facade, changed dependency/exclusivity, and changed
  unprotected command-direction diff examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all five moved clauses after normalizing only
  public/private heads and facade module qualification.
- Format, diff, whitespace, ownership, exactly-two-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

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

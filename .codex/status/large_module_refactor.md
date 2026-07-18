# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline transition-application integrity orchestration extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move single selected-activity integrity annotation/gating and batch selected
activity reintegration by timeline ID into
`Timeline.TransitionApplicationIntegrityPolicy`. `Timeline` retains private
entry points for single gating and batch reintegration. Existing integrity
annotation and selected-integrity application gating are supplied as callbacks.

Why this slice:
The reduced Timeline facade is 7,353 lines. These three exclusive clauses form
an approximately 45-line application-integrity responsibility shared by direct
and batch application helpers. The boundary preserves selected-activity
replacement before gating and batch output order.

Planned proof:
- Focused Timeline tests for reusable single applications, batch applications,
  and withheld-dependency subset rechecks.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all three moved clauses after normalizing only
  the two facade names and callback boundaries.
- Format, diff, whitespace, ownership, exactly-two-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline transition-decision integrity gate extraction, selected in `efd959ff`,
implemented in `c67c917b`, and handed off in `3221cff1`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing activity
normalization and lifecycle application.

Blocked:
No.

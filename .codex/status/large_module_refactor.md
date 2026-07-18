# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline transition-application integrity orchestration extraction.

Status:
Implementation published in `67195816`; focused and broad proof is green.

Selected boundary:
Move single selected-activity integrity annotation/gating and batch selected
activity reintegration by timeline ID into
`Timeline.TransitionApplicationIntegrityPolicy`. `Timeline` retains private
entry points for single gating and batch reintegration. Existing integrity
annotation and selected-integrity application gating are supplied as callbacks.

Why this slice:
The extraction moved three clauses into a 56-line internal module and reduced
Timeline from 7,353 to 7,332 lines. The two private entry points preserve direct
and batch application callers.

Completed proof:
- Focused transition-application integrity examples: 3 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,730 files.
- Canonical AST equivalence: all three moved clauses after normalizing only the
  two facade names and callback boundaries.
- Format, whitespace, ownership, exactly-two-facade, unchanged Timeline public
  definitions, and xref checks passed.
- Independent read-only review found no findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline transition-application integrity orchestration extraction, selected in
`4faa56ed` and implemented in `67195816`.

Next candidate:
Remap the reduced 7,332-line Timeline facade, emphasizing activity normalization
and lifecycle application.

Blocked:
No.

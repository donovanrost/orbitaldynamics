# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline lifecycle-event policy extraction.

Status:
Implementation published in `a9c981ad`; focused and broad proof is green.

Selected boundary:
Move lifecycle-event replacement derivation, review-transition precedence, and
provenance field/transition selection into `Timeline.LifecycleEventPolicy`.
`Timeline` retains the four existing private entry points. Lifecycle-event
normalization, preserved-status handling, and operator-review classification
remain Timeline-owned callbacks.

Why this slice:
The extraction moved four clauses into a 66-line internal module and reduced
Timeline from 7,332 to 7,305 lines. The four private entry points preserve the
public lifecycle-helper orchestration and all shared normalization/state
semantics.

Completed proof:
- Focused lifecycle helper example: 1 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,731 files.
- Canonical AST equivalence: all four moved clauses after normalizing only the
  four facade names and callback boundaries.
- Format, whitespace, ownership, exactly-four-facade, unchanged Timeline public
  definitions, and xref checks passed.
- Independent read-only review found no findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline lifecycle-event policy extraction, selected in `1599ab57` and
implemented in `a9c981ad`.

Next candidate:
Remap the reduced 7,305-line Timeline facade, emphasizing activity normalization
and lifecycle application.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline transition-decision integrity gate extraction.

Status:
Implementation published in `c67c917b`; focused and broad proof is green.

Selected boundary:
Move single-transition selected-activity choice, integrity annotation, and
decision upgrade into `Timeline.TransitionDecisionIntegrityPolicy`. `Timeline`
retains one private `maybe_gate_single_transition_decision_integrity/4` entry
point. Existing activity normalization, application selection, integrity
annotation/detection, selected projection/reason, list normalization, and map
compaction are supplied as callbacks.

Why this slice:
The extraction moved three clauses into a 93-line internal module and reduced
Timeline from 7,392 to 7,353 lines. The one private entry point preserves the
public transition-decision caller while applications retain the ungated base.

Completed proof:
- Focused transition decision/application examples: 2 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,729 files.
- Canonical AST equivalence: all three moved clauses after normalizing only the
  facade name and callback boundaries.
- Format, whitespace, ownership, exactly-one-facade, unchanged Timeline public
  definitions, and xref checks passed.
- Independent read-only review found no findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline transition-decision integrity gate extraction, selected in `efd959ff`
and implemented in `c67c917b`.

Next candidate:
Remap the reduced 7,353-line Timeline facade, emphasizing application integrity
orchestration and activity normalization.

Blocked:
No.

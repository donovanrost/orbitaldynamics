# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline transition-decision integrity gate extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move single-transition selected-activity choice, integrity annotation, and
decision upgrade into `Timeline.TransitionDecisionIntegrityPolicy`. `Timeline`
retains one private `maybe_gate_single_transition_decision_integrity/4` entry
point. Existing activity normalization, application selection, integrity
annotation/detection, selected projection/reason, list normalization, and map
compaction are supplied as callbacks.

Why this slice:
The reduced Timeline facade is 7,392 lines. These three exclusive clauses form
an approximately 65-line decision-integrity responsibility with no callers
outside the one public transition-decision path. The application path remains
on the ungated base decision by design.

Planned proof:
- Focused Timeline tests for reusable transition decisions and applications.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all three moved clauses after normalizing only
  the facade name and callback boundaries.
- Format, diff, whitespace, ownership, exactly-one-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline transition-helper integrity policy extraction, selected in `73d5f985`,
implemented in `ae937888`, and handed off in `0428e8a9`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing application
integrity orchestration and activity normalization.

Blocked:
No.

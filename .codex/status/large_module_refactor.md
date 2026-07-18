# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline single-transition decision policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move the complete single-transition decision builder, diff-report adapter, and
zero/one/multiple-row summarization policy into `Timeline.TransitionDecisionPolicy`.
`Timeline` retains one private `base_transition_decision/3` facade used by the
public decision and application helpers. Shared `diff_report/3` and
`compact_map/1` behavior is supplied as callbacks.

Why this slice:
The reduced Timeline facade is 7,813 lines. These six exclusive clauses form
one approximately 70-line responsibility with no callers outside the one
private facade. The boundary preserves empty, single-row, and identity-changing
multi-row semantics without moving integrity gating.

Planned proof:
- Focused Timeline tests for reusable transition decisions and applications.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all six moved clauses after normalizing only
  the facade name and the two callback boundaries.
- Format, diff, whitespace, ownership, exactly-one-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline lifecycle-state decision policy extraction, selected in `4fdafc43`,
implemented in `8c570e68`, and handed off in `95a4dd2a`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing operational
action classification and transition integrity gating.

Blocked:
No.

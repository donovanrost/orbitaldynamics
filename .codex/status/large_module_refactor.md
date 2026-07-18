# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline lifecycle-state decision policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move the complete status/approval/lifecycle decision and operator-action policy
cluster into `Timeline.LifecycleStatePolicy`: transition decisions, review
flags, import actions, operator actions/reasons, and protection aggregation.
`Timeline` retains the 11 existing private entry points used by state artifact
construction. The shared deterministic `sorted_uniq/1` behavior is supplied as
one callback to the two aggregators.

Why this slice:
The reduced Timeline facade is 7,852 lines. This approximately 115-line cluster
has one cohesive lifecycle-decision responsibility, 27 clauses, and three
exclusive protection helpers. The 11 facade entry points preserve all current
status, approval, and combined-lifecycle artifact callers.

Planned proof:
- Focused Timeline tests for status state, approval state, combined lifecycle
  state, and lifecycle summaries.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all 27 moved clauses after normalizing only
  facade names and the `sorted_uniq/1` callback boundary.
- Format, diff, whitespace, ownership, exactly-11-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline transition-application policy extraction, selected in `88e2b690` and
implemented in `4c8c2d03`, with handoff published in `a5124032`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing operational
action classification and transition-decision summarization.

Blocked:
No.

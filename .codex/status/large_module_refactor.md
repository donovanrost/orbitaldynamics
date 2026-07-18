# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline lifecycle-transition assembly policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move lifecycle transition object construction and field-specific semantic
assembly into `Timeline.LifecycleTransitionPolicy`. `Timeline` retains the
single private `lifecycle_transition/3` entry point. Status/approval category,
status/approval review, and compact-map helpers cross the boundary as callbacks.

Why this slice:
The reduced Timeline facade is 6,791 lines. These seven exclusive clauses own
added, removed, changed, and unchanged transition assembly plus field-specific
semantic merging. The initially mapped lifecycle-vocabulary candidate was
rejected because its module-attribute guards cannot cross a module boundary
without a guard-to-conditional semantic rewrite.

Planned proof:
- Focused Timeline transition/state examples covering unchanged, added,
  removed, changed, status, approval, unsupported, and review-required values.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all seven moved clauses after normalizing only
  the single facade name and callback boundaries.
- Format, diff, whitespace, ownership, exactly-one-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline lifecycle-transition review policy extraction, selected in `f1b8de8b`,
implemented in `b16a898a`, and handed off in `2c0d16f2`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing lifecycle
transition assembly and remaining activity normalization.

Blocked:
No.

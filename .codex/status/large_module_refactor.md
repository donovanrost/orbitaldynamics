# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline lifecycle-category policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move status and approval lifecycle categorization plus unsupported status and
approval predicates into `Timeline.LifecycleCategoryPolicy`. `Timeline`
retains four private entry points. Executed, terminal-exception, activity,
protected-approval, review-approval, and approval vocabulary sets cross the
boundary explicitly.

Why this slice:
The reduced Timeline facade is 6,615 lines. These 17 exclusive clauses own the
classification vocabulary shared by status-state, approval-state, combined
lifecycle-state, and transition-review surfaces: nil handling, protected and
review categories, executed and terminal categories, repairable/blocked
categories, and unsupported-value detection.

Planned proof:
- Focused unsupported-status, unsupported-approval, status-state,
  approval-state, and combined lifecycle-state examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all 17 moved clauses after normalizing only the
  four facade names and explicit vocabulary arguments.
- Format, diff, whitespace, ownership, exactly-four-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity-field value policy extraction, selected in `d7da8e84`,
implemented in `37b9114f`, and handed off in `e3890899`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing remaining
lifecycle-state assembly and summary ownership.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline lifecycle-transition review policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move status/approval transition review classification, shared review metadata
construction, and operator-review detection into
`Timeline.LifecycleTransitionReviewPolicy`. `Timeline` retains the private
status-review, approval-review, and review-detection entry points. Status lists
and existing unsupported/repairable predicates cross the boundary explicitly;
transition assembly and lifecycle categories remain Timeline-owned.

Why this slice:
The reduced Timeline facade is 6,918 lines. These nine clauses own the
precedence-sensitive review vocabulary for added, removed, and changed status
or approval values. The boundary keeps transition object assembly separate
while consolidating review decisions and reasons.

Planned proof:
- Focused Timeline transition-helper examples covering safe/unsafe status and
  approval changes, lifecycle events, unsupported values, and review detection.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all nine moved clauses after normalizing only
  the three facade names, constant arguments, and predicate callbacks.
- Format, diff, whitespace, ownership, exactly-three-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline contact-direction normalization policy extraction, selected in
`81c89fc5`, implemented in `6bc2d557`, and handed off in `10ad0dcd`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing lifecycle
transition assembly and remaining activity normalization.

Blocked:
No.

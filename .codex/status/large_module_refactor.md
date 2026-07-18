# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline lifecycle-state normalization policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move lifecycle event alias resolution, activity/approval status
canonicalization, and preserved terminal-status handling into
`Timeline.LifecycleStateNormalizationPolicy`. `Timeline` retains private entry
points for lifecycle events, lifecycle values, activity status, approval
status, and preserved-status application. Constant lists and the non-string
encoder cross the boundary explicitly.

Why this slice:
The reduced Timeline facade is 7,037 lines. These 13 clauses form the shared
lifecycle vocabulary used by reports, transitions, and lifecycle application.
The boundary keeps caller-facing private names in Timeline while consolidating
MissionPlan capability aliases and token normalization.

Planned proof:
- Focused Timeline lifecycle-helper examples for safe/unsafe events, aliases,
  status and approval canonicalization, and preserved terminal status.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all 13 moved clauses after normalizing only the
  five facade names, constant arguments, and encoder callback.
- Format, diff, whitespace, ownership, exactly-five-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline provider-contact normalization policy extraction, selected in
`a4931cc1`, implemented in `b3b22afa`, and handed off in `d0cdf412`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing activity
normalization and lifecycle application.

Blocked:
No.

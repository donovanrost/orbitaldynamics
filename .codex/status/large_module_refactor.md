# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline lifecycle-state input policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move lifecycle-state input row conversion and timeline-ID fallback into
`Timeline.LifecycleStateInputPolicy`. `Timeline` retains two private entry
points and keeps rank/group orchestration; activity input conversion, activity
map conversion, and derived timeline identity cross explicitly.

Why this slice:
The 6,269-line Timeline facade still owns two exclusive input-policy clauses
below the lifecycle-state grouping coordinator. Moving them together isolates
success/error row selection and direct/identity/derived timeline-ID fallback
without widening the grouping or summary-row coordinator boundary.

Planned proof:
- Focused lifecycle-state handoff and multi-activity summary examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for both moved clauses after normalizing only
  public/private heads and the three conversion/identity callbacks.
- Format, diff, whitespace, ownership, exactly-two-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline lifecycle-state summary metrics policy extraction, selected in
`aa4ce0bf`, implemented in `fb51c537`, and handed off in `c3d64a67`.

Next candidate:
Continue remapping the 6,269-line Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.

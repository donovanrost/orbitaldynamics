# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline lifecycle-status membership policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move executed-status membership, repairable-status membership, and both
two-clause unsupported approval/activity status predicates into
`Timeline.LifecycleStatusMembershipPolicy`. `Timeline` retains four private
entry points and passes existing executed, approval, and activity status lists
explicitly.

Why this slice:
The 6,232-line Timeline facade still owns six exclusive scalar membership
clauses used by transition review, lifecycle state, and transition application.
Moving them together isolates nil handling and exact list membership without
moving lifecycle coordinators or compile-time guard clauses.

Planned proof:
- Focused unsupported approval input, unsupported activity input, reusable
  transition membership, and lifecycle state examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all six moved clauses after normalizing only
  public/private heads, facade names, and explicit status-list arguments.
- Format, diff, whitespace, ownership, exactly-four-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline approval-protection policy extraction, initially selected in
`b506b201`, narrowed in `4b15cd10`, and implemented in `32aba82d`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.

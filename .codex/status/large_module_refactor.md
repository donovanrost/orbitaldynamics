# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline approval-protection policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move the fallback lock/approval preservation-sensitive source clause and
approval-protection membership into `Timeline.ApprovalProtectionPolicy`.
`Timeline` retains the guarded executed-source clause plus two private entry
points and passes only the protected approval-status list explicitly; diff-row
callbacks remain unchanged.

Why this slice:
The original complete-family selection cannot pass `@executed_statuses`
explicitly without changing or duplicating the compile-time `in` guard. Keeping
that clause in Timeline preserves it exactly while the two remaining exclusive
clauses isolate truthy lock behavior and approval membership without moving the
diff coordinator or protection-decision assembly.

Planned proof:
- Focused changed protected/executed, changed unprotected, and removed
  protected/executed diff examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for both moved clauses after normalizing only
  public/private heads, facade names, and the protected-status argument.
- Format, diff, whitespace, ownership, exactly-two-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline terminal-exception classification policy extraction, selected in
`c77b9c61` and implemented in `2712e34d`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.

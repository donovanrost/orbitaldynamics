# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline lifecycle-status membership policy extraction.

Status:
Implemented, verified, independently reviewed, committed, and pushed.

Completed boundary:
Moved executed-status membership, repairable-status membership, and both
two-clause unsupported approval/activity predicates into the 14-line
`Timeline.LifecycleStatusMembershipPolicy`. The 6,246-line `Timeline` retains
four private entry points and passes all status lists explicitly.

Published commits:
Selected in `873251c3` and implemented in `804f0f70`.

Verification:
- Strict warnings-as-errors compile passed across 3,775 files.
- Four focused unsupported approval/activity, reusable transition, and
  lifecycle state examples passed.
- Full Timeline suite passed with 127 examples; Timeline schema-contract suites
  passed with 36 examples.
- Canonical AST equivalence passed for all six moved clauses after normalizing
  only public/private heads, facade names, and status-list arguments.
- Format, diff, whitespace, ownership, exactly-four-facade, unchanged Timeline
  public-definition, and xref checks passed.
- Independent read-only review found no production-code issues; compile-time
  lifecycle category guards remain byte-for-byte unchanged.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline lifecycle-status membership policy extraction, selected in `873251c3`
and implemented in `804f0f70`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.

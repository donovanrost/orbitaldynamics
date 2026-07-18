# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline stable-identifier policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move Timeline's stable binary identifier regex predicate into
`Timeline.StableIdentifierPolicy`. `Timeline` retains one private entry point
and passes the existing compiled regex explicitly; all input, cadence import,
identity, and relationship callbacks remain unchanged.

Why this slice:
The 6,260-line Timeline facade still owns one exclusive validation leaf shared
across input review and reference normalization. Moving it isolates exact binary
guard and regex-match behavior without moving any identity coordinator or
changing the regex owner.

Planned proof:
- Focused malformed activity identity, malformed identity fields, and malformed
  relationship-list examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for the moved guarded definition after normalizing
  only the public/private head, facade name, and explicit regex argument.
- Format, diff, whitespace, ownership, exactly-one-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline integrity issue-construction policy extraction, selected in `73a1628b`
and implemented in `12a69a75`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.

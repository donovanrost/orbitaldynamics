# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity operational-kind policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move activity-type, contact-direction, and ground-station operational-kind
classification into `Timeline.ActivityOperationalKindPolicy`. `Timeline`
retains one private entry point. The boundary has no callbacks or shared
vocabulary arguments.

Why this slice:
The reduced Timeline facade is 6,615 lines. These 10 exclusive clauses own the
precedence that maps explicit activity types, contact directions, and
ground-station evidence into the operational-kind vocabulary used by report
rows and import/action policy. The previously selected lifecycle-category
boundary was rejected before implementation because its `in` guards require
compile-time vocabulary ownership and cannot preserve clause structure with
runtime vocabulary arguments.

Planned proof:
- Focused command, observation, maneuver, attitude, coast, contact-direction,
  ground-station fallback, and generic activity examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all 10 moved clauses after normalizing only the
  single facade name.
- Format, diff, whitespace, ownership, exactly-one-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity-field value policy extraction, selected in `d7da8e84`,
implemented in `37b9114f`, and handed off in `e3890899`.

Next candidate:
Remap the reduced Timeline facade after this slice; lifecycle-category
extraction requires an explicit compile-time vocabulary ownership decision.

Blocked:
No.

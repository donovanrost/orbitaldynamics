# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity thermal-metric policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move temperature alias selection, explicit thermal margin selection, and
one-/two-sided derived thermal margin calculation into
`Timeline.ActivityThermalMetricPolicy`. `Timeline` retains six private entry
points; numeric field selection crosses the boundary explicitly. Derived margin
calculation becomes internal to the policy.

Why this slice:
The reduced Timeline facade is 6,383 lines. These 10 exclusive clauses own
temperature field aliases, observed/planned/actual precedence inputs, explicit
margin precedence, and derived lower/upper/bounded margin arithmetic used by
thermal activity context and diff surfaces.

Planned proof:
- Focused explicit, lower-only, upper-only, bounded, numeric-string, alias, and
  thermal-diff examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all 10 moved clauses after normalizing only the
  six facade names and numeric selector callback.
- Format, diff, whitespace, ownership, exactly-six-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity numeric-value policy extraction, selected in `52240076`,
implemented in `344471d0`, and handed off in `f0a7e782`.

Next candidate:
Remap the reduced Timeline facade after this slice, avoiding the wide
activity-to-map coordinator callback surface.

Blocked:
No.

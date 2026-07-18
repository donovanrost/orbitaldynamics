# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline identity-grouping policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move normalized activity grouping by timeline ID, unique-or-nil activity
selection, and deterministic activity-ID ordering within timeline row groups
into `Timeline.IdentityGroupingPolicy`. `Timeline` retains three private entry
points; activity normalization crosses the boundary explicitly.

Why this slice:
The 6,268-line Timeline facade still owns three exclusive clauses that define
timeline-identity grouping semantics shared by operational, diff, and
transition-application paths. Moving them together isolates grouping keys,
duplicate/missing behavior, and within-group ordering without extracting
duplicate annotation or report coordinators.

Planned proof:
- Focused operational duplicate identity, transition application, and timeline
  diff duplicate-collision examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all three moved clauses after normalizing only
  public/private heads and the activity normalization callback.
- Format, diff, whitespace, ownership, exactly-three-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline deterministic count-summary policy extraction, selected in `254c0c28`,
implemented in `e822e150`, and handed off in `362474a4`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.

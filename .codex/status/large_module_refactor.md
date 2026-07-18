# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity row-alias policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move provider `activity_id`/`activity_type` insertion into canonical `id`/`type`
fields plus nil/empty guarded put-new behavior into
`Timeline.ActivityRowAliasPolicy`. `Timeline` retains two private entry points.
The boundary has no callbacks, module attributes, or shared vocabulary
arguments.

Why this slice:
The reduced Timeline facade is 6,532 lines. These three exclusive clauses own
canonical activity ID/type alias insertion and the shared present-only,
non-overwriting field insertion semantics reused by source-window and
cadence-import normalization.

Planned proof:
- Focused provider activity aliases, canonical-field precedence, nil/empty
  filtering, source-window, and cadence-import normalization examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all three moved clauses after normalizing only
  the two facade names.
- Format, diff, whitespace, ownership, exactly-two-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity relationship policy extraction, selected in `3fdbecd8`,
implemented in `374151ea`, and handed off in `e7fbb933`.

Next candidate:
Remap the reduced Timeline facade after this slice, avoiding the wide
activity-to-map coordinator callback surface.

Blocked:
No.

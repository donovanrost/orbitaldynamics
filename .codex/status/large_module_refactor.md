# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity relationship policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move dependency and exclusivity activity/timeline ID field selection, explicit
versus fallback precedence, and duplicate-reference selection into
`Timeline.ActivityRelationshipPolicy`. `Timeline` retains eight private entry
points. Field lookup and general/map-only normalize/duplicate operations cross
the boundary explicitly.

Why this slice:
The reduced Timeline facade is 6,568 lines. These eight exclusive clauses own
the alias lists and explicit/fallback precedence that turn dependency,
exclusion, and exclusivity fields into activity/timeline ID and duplicate-ID
surfaces used by integrity, diff, transition, and publication behavior.

Planned proof:
- Focused dependency/exclusivity scalar, map, explicit, fallback, duplicate,
  malformed, and deterministic-order examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all eight moved clauses after normalizing only
  the eight facade names and five callback boundaries.
- Format, diff, whitespace, ownership, exactly-eight-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity identity policy extraction, selected in `c05b969c`,
implemented in `40a099b3`, and handed off in `5cfc8a5d`.

Next candidate:
Remap the reduced Timeline facade after this slice, avoiding boundaries whose
guard vocabularies remain shared with Timeline.

Blocked:
No.

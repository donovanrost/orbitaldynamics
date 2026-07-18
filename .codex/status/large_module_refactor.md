# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity-identity normalization policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move spacecraft, ground-station, and target identity canonicalization plus the
exclusive nested-identity lookup helpers into
`Timeline.ActivityIdentityNormalizationPolicy`. `Timeline` retains the three
normalization entry points used by `activity_to_map/1`.

Why this slice:
The reduced Timeline facade is 7,305 lines. These 11 exclusive clauses own the
precedence from canonical IDs to aliases to nested provider objects for the
three activity identity dimensions. The boundary preserves pipeline order and
leaves string encoding and downstream timeline-identity construction
unchanged.

Planned proof:
- Focused Timeline examples for nested spacecraft/satellite, station aliases
  and objects, target objects, and changed spacecraft assignment.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all 11 moved clauses after normalizing only the
  three facade names.
- Format, diff, whitespace, ownership, exactly-three-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline lifecycle-event policy extraction, selected in `1599ab57`, implemented
in `a9c981ad`, and handed off in `06a3b36c`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing activity
normalization and lifecycle application.

Blocked:
No.

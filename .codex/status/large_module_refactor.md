# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline station-calendar status normalization policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move station-calendar scalar/list status canonicalization and nested source
evidence normalization into
`Timeline.StationCalendarStatusNormalizationPolicy`. `Timeline` retains the
single normalization entry point used by `activity_to_map/1`.

Why this slice:
The reduced Timeline facade is 7,258 lines. These nine exclusive clauses own
status token normalization for top-level station-calendar fields, lists, and
nested source entries/overlaps. The boundary preserves field order and leaves
all non-status station-calendar context derivation in Timeline.

Planned proof:
- Focused Timeline examples for provider string and atom-shaped reservation,
  contention, list, and nested source statuses.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all nine moved clauses after normalizing only
  the single facade name.
- Format, diff, whitespace, ownership, exactly-one-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity-identity normalization policy extraction, selected in
`82fdd813`, implemented in `2b825450`, and handed off in `710ca5a8`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing activity
normalization and lifecycle application.

Blocked:
No.

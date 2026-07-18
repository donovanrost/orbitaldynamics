# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity-reference ID policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move scalar/map reference flattening, normalized stable-ID lists, duplicate-ID
lists, and scalar stable-ID filtering into
`Timeline.ActivityReferenceIdPolicy`. `Timeline` retains the four private
normalize/duplicate entry points for general and map-only references. The
stable-activity-ID predicate crosses the boundary explicitly.

Why this slice:
The reduced Timeline facade is 6,759 lines. These 24 exclusive clauses own the
reference-ID semantics shared by dependency, exclusivity, objective, and data
product surfaces: input-shape filtering, comma splitting, stable-ID validation,
deduplication, duplicate detection, and deterministic sorting.

Planned proof:
- Focused dependency/exclusivity examples for scalar strings, malformed IDs,
  nested maps, duplicates, booleans, atoms, integers, and deterministic order.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all 24 moved clauses after normalizing only the
  four facade names and stable-ID predicate callback.
- Format, diff, whitespace, ownership, exactly-four-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline invalid lifecycle-state input policy extraction, selected in
`070962e4`, implemented in `7099753c`, and handed off in `33f34a72`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing remaining
activity normalization and lifecycle state assembly.

Blocked:
No.

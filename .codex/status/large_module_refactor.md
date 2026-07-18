# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline publication identifier policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move publication source-artifact ID precedence/defaulting, option ID-list
normalization, summary ID-list normalization, and changed-field ID-array map
normalization into `Timeline.PublicationIdentifierPolicy`. `Timeline` retains
four private entry points; stable-ID normalization and sorted uniqueness cross
the boundary explicitly.

Why this slice:
The 6,324-line Timeline facade still owns seven clauses for one publication
identifier responsibility. Moving source-ID precedence, list normalization,
map-key filtering, and deterministic sorting together preserves the
publication-summary map coordinator without widening its callback surface.

Planned proof:
- Focused publication summary example covering source ID precedence,
  duplicate/sorted option IDs, normalized diff ID lists/maps, and schema
  validation.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all seven moved clauses after normalizing only
  four facade names plus stable-ID/sorted-unique callbacks.
- Format, diff, whitespace, ownership, exactly-four-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline publication source-summary policy extraction, selected in `12f85c09`,
implemented in `abea4c55`, and handed off in `5436345d`.

Next candidate:
Continue remapping the reduced Timeline publication helpers after this slice,
avoiding the wide publication-summary and activity-context map coordinator
callback surfaces.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline publication scalar-input policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move source-artifact type precedence/defaulting and publication-sequence
parsing/validation into `Timeline.PublicationScalarInputPolicy`. `Timeline`
retains two private entry points; artifact-value encoding crosses the boundary
explicitly.

Why this slice:
These are the last two exclusive scalar-input clauses adjacent to the
publication-summary coordinator in the 6,310-line Timeline facade. Moving them
together isolates artifact-type precedence, defaulting, option fallback, full
integer parsing, non-negative validation, and exact error wording without
extracting the coordinator map.

Planned proof:
- Focused publication summary example covering source-artifact type selection,
  string/integer publication sequence handling, facade parity, and schema
  validation.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for both moved clauses after normalizing only two
  facade names plus the artifact encoder callback.
- Format, diff, whitespace, ownership, exactly-two-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline publication identifier policy extraction, selected in `0c8d22f3`,
implemented in `20d73eb0`, and handed off in `763c3f9c`.

Next candidate:
Remap the reduced Timeline facade beyond the publication helper cluster after
this slice, avoiding the wide publication-summary and activity-context map
coordinator callback surfaces.

Blocked:
No.

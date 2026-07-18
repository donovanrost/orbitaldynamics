# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline publication source-summary policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move dependency-impact and timeline-diff source-summary recognition plus
optional source-summary embedding into
`Timeline.PublicationSourceSummaryPolicy`. `Timeline` retains four private
entry points; key stringification and the two accepted schema-contract values
cross the boundary explicitly.

Why this slice:
The 6,330-line Timeline facade still owns eight contiguous clauses that decide
whether dependency-impact and diff summaries are recognized, discarded, or
embedded. Moving these clauses together preserves the publication-summary map
coordinator while isolating schema/model fallback order and empty-summary
handling.

Planned proof:
- Focused publication summary example covering recognized dependency/diff
  summaries, absent-summary fallbacks, optional embedding, and schema
  validation.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all eight moved clauses after normalizing only
  four facade names plus stringifier/schema-contract arguments.
- Format, diff, whitespace, ownership, exactly-four-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline publication invalidation policy extraction, selected in `a599aed4`,
implemented in `615d4d3c`, and handed off in `078878e6`.

Next candidate:
Continue remapping the reduced Timeline publication helpers after this slice,
avoiding the wide publication-summary and activity-context map coordinator
callback surfaces.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline publication source-summary policy extraction.

Status:
Implementation published in `abea4c55`; focused and broad proof is green.

Selected boundary:
Move dependency-impact and timeline-diff source-summary recognition plus
optional source-summary embedding into
`Timeline.PublicationSourceSummaryPolicy`. `Timeline` retains four private
entry points; key stringification and the two accepted schema-contract values
cross the boundary explicitly.

Why this slice:
The extraction moved eight contiguous clauses into a 37-line internal module
and reduced Timeline from 6,330 to 6,324 lines. Four private entry points
preserve the publication-summary coordinator while schema/model fallback order
and empty-summary embedding now live together.

Completed proof:
- Focused publication summary example: 1 passed, covering recognized
  dependency/diff summaries, absent-summary fallbacks, optional embedding, and
  schema validation.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,755 files.
- Canonical AST equivalence: all eight moved clauses after normalizing only
  public/private heads, the stringifier callback, and schema-contract
  arguments.
- Format, whitespace, ownership, exactly-four-facade, unchanged Timeline public
  definitions, and xref checks passed; Timeline is the only runtime caller.
- Independent read-only review found no production-code findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline publication source-summary policy extraction, selected in `12f85c09`
and implemented in `abea4c55`.

Next candidate:
Continue remapping the 6,324-line Timeline publication helpers after this slice,
avoiding the wide publication-summary and activity-context map coordinator
callback surfaces.

Blocked:
No.

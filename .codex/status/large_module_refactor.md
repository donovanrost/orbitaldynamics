# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline publication identifier policy extraction.

Status:
Implementation published in `20d73eb0`; focused and broad proof is green.

Selected boundary:
Move publication source-artifact ID precedence/defaulting, option ID-list
normalization, summary ID-list normalization, and changed-field ID-array map
normalization into `Timeline.PublicationIdentifierPolicy`. `Timeline` retains
four private entry points; stable-ID normalization and sorted uniqueness cross
the boundary explicitly.

Why this slice:
The extraction moved seven clauses into a 50-line internal module and reduced
Timeline from 6,324 to 6,310 lines. Four private entry points preserve the
publication-summary coordinator while source-ID precedence, list
normalization, map-key filtering, and deterministic sorting now live together.

Completed proof:
- Focused publication summary example: 1 passed, covering source ID
  precedence, duplicate/sorted option IDs, normalized diff ID lists/maps, and
  schema validation.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,756 files.
- Canonical AST equivalence: all seven moved clauses after normalizing only
  public/private heads, stable-ID/sorted-unique callbacks, and internal
  ID-list callback threading.
- Format, whitespace, ownership, exactly-four-facade, unchanged Timeline public
  definitions, and xref checks passed; Timeline is the only runtime caller.
- Independent read-only review found no production-code findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline publication identifier policy extraction, selected in `0c8d22f3` and
implemented in `20d73eb0`.

Next candidate:
Continue remapping the 6,310-line Timeline publication helpers after this slice,
avoiding the wide publication-summary and activity-context map coordinator
callback surfaces.

Blocked:
No.

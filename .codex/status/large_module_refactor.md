# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline publication scalar-input policy extraction.

Status:
Implementation published in `e5df6b2a`; focused and broad proof is green.

Selected boundary:
Move source-artifact type precedence/defaulting and publication-sequence
parsing/validation into `Timeline.PublicationScalarInputPolicy`. `Timeline`
retains two private entry points; artifact-value encoding crosses the boundary
explicitly.

Why this slice:
The extraction moved both clauses into a 33-line internal module and reduced
Timeline from 6,310 to 6,291 lines. Two private entry points preserve the
publication-summary coordinator while artifact-type precedence/defaulting and
sequence parsing/validation now live together.

Completed proof:
- Focused publication summary example: 1 passed, covering source-artifact type
  selection, string/integer publication sequence handling, facade parity, and
  schema validation.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,757 files.
- Canonical AST equivalence: both moved clauses after normalizing only
  public/private heads and the artifact encoder callback.
- Format, whitespace, ownership, exactly-two-facade, unchanged Timeline public
  definitions, and xref checks passed; Timeline is the only runtime caller.
- Independent read-only review found no production-code findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline publication scalar-input policy extraction, selected in `93af9e7a` and
implemented in `e5df6b2a`.

Next candidate:
Remap the 6,291-line Timeline facade beyond the publication helper cluster after
this slice, avoiding the wide publication-summary and activity-context map
coordinator callback surfaces.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline publication invalidation policy extraction.

Status:
Implementation published in `615d4d3c`; focused and broad proof is green.

Selected boundary:
Move downstream invalidation ID selection and validation, reason
classification/grouping/counting, publication/downstream status selection, and
publication-summary ID construction into
`Timeline.PublicationInvalidationPolicy`. `Timeline` retains seven private
entry points; the dependency-impact review predicate becomes policy-internal.

Why this slice:
The extraction moved 13 contiguous, pure clauses into a 100-line internal
module and reduced Timeline from 6,366 to 6,330 lines. Seven private entry
points preserve the publication-summary coordinator while invalidation
validation, precedence, grouping, status selection, and ID construction now
live together.

Completed proof:
- Focused publication summary example: 1 passed, covering dependency-impact
  invalidation, supersession identity, no-impact status, grouped reason counts,
  schema validation, and invalid explicit invalidation IDs.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,754 files.
- Canonical AST equivalence: all 13 moved clauses after normalizing only
  public/private heads.
- Format, whitespace, ownership, exactly-seven-facade, unchanged Timeline
  public definitions, and xref checks passed; Timeline is the only runtime
  caller.
- Independent read-only review found no production-code findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline publication invalidation policy extraction, selected in `a599aed4` and
implemented in `615d4d3c`.

Next candidate:
Continue remapping the 6,330-line Timeline facade after this slice, avoiding the
wide publication-summary and activity-context map coordinator callback
surfaces.

Blocked:
No.

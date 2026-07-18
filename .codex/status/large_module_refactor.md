# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline deterministic count-summary policy extraction.

Status:
Implementation published in `e822e150`; focused and broad proof is green.

Selected boundary:
Move duplicate-group/activity totals, generic field counts, changed-field
counts, transition type/category counts, and deterministic count-map sorting
into `Timeline.CountSummaryPolicy`. `Timeline` retains seven private entry
points; changed-field list extraction crosses the boundary explicitly.

Why this slice:
The extraction moved seven clauses into a 54-line internal module and reduced
Timeline from 6,291 to 6,268 lines. Seven private entry points preserve all
report coordinators while nil filtering, frequency calculation, duplicate
cardinality, transition path selection, and stable map ordering now live
together.

Completed proof:
- Focused operational count, duplicate identity, transition application
  summary, and timeline-diff changed/transition count examples: 4 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,758 files.
- Canonical AST equivalence: all seven moved clauses after normalizing only
  public/private heads and the changed-field list callback.
- Format, whitespace, ownership, exactly-seven-facade, unchanged Timeline
  public definitions, and xref checks passed; Timeline is the only runtime
  caller.
- Independent read-only review found no production-code findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline deterministic count-summary policy extraction, selected in `254c0c28`
and implemented in `e822e150`.

Next candidate:
Continue remapping the 6,268-line Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.

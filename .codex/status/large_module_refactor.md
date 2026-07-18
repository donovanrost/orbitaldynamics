# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline protection-summary policy extraction.

Status:
Implementation published in `ac9421ae`; focused and broad proof is green.

Selected boundary:
Move filtered protection-decision IDs, protection-category activity-ID sets,
deterministic ID sorting, and preservation status precedence into
`Timeline.ProtectionSummaryPolicy`. `Timeline` retains four private entry
points; sorted uniqueness crosses the boundary explicitly.

Why this slice:
The extraction moved six clauses into a 35-line internal module. Timeline
retains four private entry points and is now 6,268 lines; the five-line facade
increase is the cost of making sorted uniqueness explicit at all three ID
boundaries. Decision/category filtering, grouped ID-set ordering, and
review-over-preserve-over-clear precedence now live together.

Completed proof:
- Focused lifecycle preservation summary/status and protection-decision
  classification examples: 3 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,760 files.
- Canonical AST equivalence: all six moved clauses after normalizing only
  public/private heads, sorted-unique callbacks, and internal grouped-ID
  callback threading.
- Format, whitespace, ownership, exactly-four-facade, unchanged Timeline public
  definitions, and xref checks passed; Timeline is the only runtime caller.
- Independent read-only review found no production-code findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline protection-summary policy extraction, selected in `3d551921` and
implemented in `ac9421ae`.

Next candidate:
Continue remapping the 6,268-line Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.

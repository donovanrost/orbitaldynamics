# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline lifecycle-state summary metrics policy extraction.

Status:
Implementation published in `fb51c537`; focused and broad proof is green.

Selected boundary:
Move duplicate match counts, planned/realized match activity IDs,
operator-action reason frequencies, filtered timeline IDs, and flattened review
activity IDs into `Timeline.LifecycleStateSummaryMetricsPolicy`. `Timeline`
retains five private entry points; list extraction, count-map sorting, and
sorted uniqueness cross the boundary explicitly.

Why this slice:
The extraction moved six clauses into a 40-line internal module and reduced
Timeline from 6,270 to 6,269 lines. Five private entry points preserve summary
row assembly while duplicate cardinality, ID fallback order, row filtering,
flattened activity-ID collection, reason frequencies, and deterministic
ordering now live together.

Completed proof:
- Focused lifecycle-state handoff and multi-activity summary examples: 2 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,762 files.
- Canonical AST equivalence: all six moved clauses after normalizing only
  public/private heads, list/sort callbacks, and internal callback threading.
- Format, whitespace, ownership, exactly-five-facade, unchanged Timeline public
  definitions, and xref checks passed; Timeline is the only runtime caller.
- Independent read-only review found no production-code findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline lifecycle-state summary metrics policy extraction, selected in
`aa4ce0bf` and implemented in `fb51c537`.

Next candidate:
Continue remapping the 6,269-line Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.

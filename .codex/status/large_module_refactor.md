# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline transition-application activity policy extraction.

Status:
Implementation published in `2c96d882`; focused and broad proof is green.

Selected boundary:
Move nil/non-nil transition-application activity normalization and preservation
of existing transition-application provenance into
`Timeline.TransitionApplicationActivityPolicy`. `Timeline` retains two private
entry points; activity normalization crosses the boundary explicitly.

Why this slice:
The extraction moved three clauses into a 16-line internal module. Timeline
retains two private entry points and is now 6,270 lines; the two-line facade
increase makes activity normalization explicit. Nil behavior, normalization
dispatch, provenance-map matching, and no-op fallback now live together.

Completed proof:
- Focused transition application and helper-provenance examples: 2 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,761 files.
- Canonical AST equivalence: all three moved clauses after normalizing only
  public/private heads and the activity normalization callback.
- Format, whitespace, ownership, exactly-two-facade, unchanged Timeline public
  definitions, and xref checks passed; Timeline is the only runtime caller.
- Independent read-only review found no production-code findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline transition-application activity policy extraction, selected in
`fed4f449` and implemented in `2c96d882`.

Next candidate:
Continue remapping the 6,270-line Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.

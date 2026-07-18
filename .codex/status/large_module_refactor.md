# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline lifecycle-state input policy extraction.

Status:
Implementation published in `b1a9a980`; focused and broad proof is green.

Selected boundary:
Move lifecycle-state input row conversion and timeline-ID fallback into
`Timeline.LifecycleStateInputPolicy`. `Timeline` retains two private entry
points and keeps rank/group orchestration; activity input conversion, activity
map conversion, and derived timeline identity cross explicitly.

Why this slice:
The extraction moved both clauses into a 19-line internal module. Timeline
retains two private entry points and is now 6,272 lines; the three-line facade
increase makes input/map/identity dependencies explicit. Success/error row
selection and direct/identity/derived timeline-ID fallback now live together.

Completed proof:
- Focused lifecycle-state handoff and multi-activity summary examples: 2 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,763 files.
- Canonical AST equivalence: both moved clauses after normalizing only
  public/private heads and the three conversion/identity callbacks.
- Format, whitespace, ownership, exactly-two-facade, unchanged Timeline public
  definitions, and xref checks passed; Timeline is the only runtime caller.
- Independent read-only review found no production-code findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline lifecycle-state input policy extraction, selected in `36dabe24` and
implemented in `b1a9a980`.

Next candidate:
Continue remapping the 6,272-line Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.

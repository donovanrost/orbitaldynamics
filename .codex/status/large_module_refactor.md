# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline identity-grouping policy extraction.

Status:
Implementation published in `ffbcd5f0`; focused and broad proof is green.

Selected boundary:
Move normalized activity grouping by timeline ID, unique-or-nil activity
selection, and deterministic activity-ID ordering within timeline row groups
into `Timeline.IdentityGroupingPolicy`. `Timeline` retains three private entry
points; activity normalization crosses the boundary explicitly.

Why this slice:
The extraction moved three clauses into a 24-line internal module and reduced
Timeline from 6,268 to 6,263 lines. Three private entry points preserve
operational, diff, and transition-application coordinators while grouping keys,
duplicate/missing behavior, and within-group ordering now live together.

Completed proof:
- Focused operational duplicate identity, transition application, and timeline
  diff duplicate-collision examples: 3 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,759 files.
- Canonical AST equivalence: all three moved clauses after normalizing only
  public/private heads and the activity normalization callback.
- Format, whitespace, ownership, exactly-three-facade, unchanged Timeline
  public definitions, and xref checks passed; Timeline is the only runtime
  caller.
- Independent read-only review found no production-code findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline identity-grouping policy extraction, selected in `e1ff48a7` and
implemented in `ffbcd5f0`.

Next candidate:
Continue remapping the 6,263-line Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.

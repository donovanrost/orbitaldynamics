# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity thermal-metric policy extraction.

Status:
Implementation published in `dacfb2bd`; focused and broad proof is green.

Selected boundary:
Move temperature alias selection, explicit thermal margin selection, and
one-/two-sided derived thermal margin calculation into
`Timeline.ActivityThermalMetricPolicy`. `Timeline` retains six private entry
points; numeric field selection crosses the boundary explicitly. Derived margin
calculation becomes internal to the policy.

Why this slice:
The extraction moved 10 clauses into a 65-line internal module and reduced
Timeline from 6,383 to 6,364 lines. Six private entry points preserve thermal
activity context and diff callers while moving temperature aliases, explicit
margin precedence, selector evaluation order, and bounded/one-sided arithmetic
out of the facade.

Completed proof:
- Focused numeric-string, bounded-margin, and thermal-diff examples: 3 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,752 files.
- Canonical AST equivalence: all 10 moved clauses after normalizing only the
  six facade names and numeric selector callback.
- Format, whitespace, ownership, exactly-six-facade, unchanged Timeline public
  definitions, and xref checks passed; Timeline is the only runtime caller.
- Independent read-only review found no production-code findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity thermal-metric policy extraction, selected in `fde9f37a` and
implemented in `dacfb2bd`.

Next candidate:
Remap the reduced 6,364-line Timeline facade, avoiding the wide activity-to-map
coordinator callback surface.

Blocked:
No.

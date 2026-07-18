# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity row-alias policy extraction.

Status:
Implementation published in `da390b5d`; focused and broad proof is green.

Selected boundary:
Move provider `activity_id`/`activity_type` insertion into canonical `id`/`type`
fields plus nil/empty guarded put-new behavior into
`Timeline.ActivityRowAliasPolicy`. `Timeline` retains two private entry points.
The boundary has no callbacks, module attributes, or shared vocabulary
arguments.

Why this slice:
The extraction moved three clauses into a 15-line internal module and reduced
Timeline from 6,532 to 6,528 lines. Two private entry points preserve the
activity conversion coordinator plus source-window and cadence-import callback
callers while moving canonical alias and present-only non-overwriting insertion
semantics out of the facade.

Completed proof:
- Focused provider alias, canonical precedence, source-window, and
  cadence-import examples: 5 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,749 files.
- Canonical AST equivalence: all three moved clauses after normalizing only
  the two facade names.
- Format, whitespace, ownership, exactly-two-facade, unchanged Timeline public
  definitions, and xref checks passed; Timeline is the only runtime caller.
- Independent read-only review found no production-code findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity row-alias policy extraction, selected in `b443c84e` and
implemented in `da390b5d`.

Next candidate:
Remap the reduced 6,528-line Timeline facade, avoiding the wide activity-to-map
coordinator callback surface.

Blocked:
No.

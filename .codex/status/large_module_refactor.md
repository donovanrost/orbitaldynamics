# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity numeric-normalization policy extraction.

Status:
Implementation published in `9eb1ad8d`; focused and broad proof is green.

Selected boundary:
Move the exclusive numeric activity-field vocabulary, canonical/alternate time
normalization, and optional numeric-field conversion/deletion into
`Timeline.ActivityNumericNormalizationPolicy`. `Timeline` retains two private
entry points; numeric parsing crosses the boundary explicitly. The per-field
helper becomes internal to the policy.

Why this slice:
The extraction moved three clauses and the exact 116-field vocabulary into a
152-line internal module and reduced Timeline from 6,528 to 6,396 lines. Two
private entry points preserve the activity conversion coordinator while moving
numeric string conversion, invalid-field removal, canonical time precedence,
and alternate time fallback out of the facade.

Completed proof:
- Focused timing, numeric-string context, throughput, link-quality, and thermal
  examples: 5 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,750 files.
- Canonical AST equivalence: the exact 116-field vocabulary and all three moved
  clauses after normalizing only
  the two facade names, numeric callback, and attribute relocation.
- Format, whitespace, vocabulary ownership, exactly-two-facade, unchanged
  Timeline public definitions, and xref checks passed; Timeline is the only
  runtime caller.
- Independent read-only review found no production-code findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity numeric-normalization policy extraction, selected in
`c0138e37` and implemented in `9eb1ad8d`.

Next candidate:
Remap the reduced 6,396-line Timeline facade, avoiding the wide activity-to-map
coordinator callback surface.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline station-calendar status normalization policy extraction.

Status:
Implementation published in `86c63a95`; focused and broad proof is green.

Selected boundary:
Move station-calendar scalar/list status canonicalization and nested source
evidence normalization into
`Timeline.StationCalendarStatusNormalizationPolicy`. `Timeline` retains the
single normalization entry point used by `activity_to_map/1`.

Why this slice:
The extraction moved nine clauses into a 90-line internal module and reduced
Timeline from 7,258 to 7,175 lines. The single private entry point preserves
`activity_to_map/1` pipeline order while scalar/list and nested-source helpers
stay private to the new policy.

Completed proof:
- Focused station-calendar normalization examples: 2 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,733 files.
- Canonical AST equivalence: all nine moved clauses after normalizing only the
  single facade name.
- Format, whitespace, ownership, exactly-one-facade, unchanged Timeline public
  definitions, and xref checks passed.
- Independent read-only review found no findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline station-calendar status normalization policy extraction, selected in
`b1e680a8` and implemented in `86c63a95`.

Next candidate:
Remap the reduced 7,175-line Timeline facade, emphasizing activity normalization
and lifecycle application.

Blocked:
No.

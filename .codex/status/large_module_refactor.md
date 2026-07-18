# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity-identity normalization policy extraction.

Status:
Implementation published in `2b825450`; focused and broad proof is green.

Selected boundary:
Move spacecraft, ground-station, and target identity canonicalization plus the
exclusive nested-identity lookup helpers into
`Timeline.ActivityIdentityNormalizationPolicy`. `Timeline` retains the three
normalization entry points used by `activity_to_map/1`.

Why this slice:
The extraction moved 11 clauses into a 63-line internal module and reduced
Timeline from 7,305 to 7,258 lines. The three private entry points preserve
`activity_to_map/1` pipeline order while nested lookup stays private to the new
policy.

Completed proof:
- Focused activity-identity examples: 3 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,732 files.
- Canonical AST equivalence: all 11 moved clauses after normalizing only the
  three facade names.
- Format, whitespace, ownership, exactly-three-facade, unchanged Timeline public
  definitions, and xref checks passed.
- Independent read-only review found no findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity-identity normalization policy extraction, selected in
`82fdd813` and implemented in `2b825450`.

Next candidate:
Remap the reduced 7,258-line Timeline facade, emphasizing activity normalization
and lifecycle application.

Blocked:
No.

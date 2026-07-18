# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline provider-contact normalization policy extraction.

Status:
Implementation published in `b3b22afa`; focused and broad proof is green.

Selected boundary:
Move activity-type alias promotion, provider downlink inference, direction-based
contact inference, and command-feedback suppression into
`Timeline.ProviderContactNormalizationPolicy`. `Timeline` retains the three
ordered normalization entry points used by `activity_to_map/1`.

Why this slice:
The extraction moved eight clauses into a 64-line internal module and reduced
Timeline from 7,082 to 7,037 lines. The three private entry points preserve the
type-alias, inferred-downlink, then direction-contact pipeline order.

Completed proof:
- Focused provider-contact normalization examples: 2 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,735 files.
- Canonical AST equivalence: all eight moved clauses after normalizing only the
  three facade names.
- Format, whitespace, ownership, exactly-three-facade, unchanged Timeline public
  definitions, and xref checks passed.
- Independent read-only review found no findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline provider-contact normalization policy extraction, selected in
`a4931cc1` and implemented in `b3b22afa`.

Next candidate:
Remap the reduced 7,037-line Timeline facade, emphasizing activity normalization
and lifecycle application.

Blocked:
No.

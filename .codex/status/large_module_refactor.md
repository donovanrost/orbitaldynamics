# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline selected-integrity policy extraction.

Status:
Implementation published in `90858060`; focused and broad proof is green.

Selected boundary:
Move selected-activity application gating, the complete selected-integrity
projection, review action/status upgrades, and deterministic reason formatting
into `Timeline.SelectedIntegrityPolicy`. `Timeline` retains private entry points
for application gating, context projection, and reason formatting. Integrity
review detection, list normalization, and map compaction are supplied as
callbacks.

Why this slice:
The extraction moved eight clauses into an 89-line internal module and reduced
Timeline from 7,491 to 7,429 lines. The three private entry points preserve
direct decisions, single/batch applications, and transition helper errors.

Completed proof:
- Focused selected-integrity examples: 4 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,727 files.
- Canonical AST equivalence: all eight moved clauses after normalizing only the
  three facade names and callback boundaries.
- Format, whitespace, ownership, exactly-three-facade, unchanged Timeline
  public definitions, and xref checks passed.
- Independent read-only review found no findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline selected-integrity policy extraction, selected in `135fa967` and
implemented in `90858060`.

Next candidate:
Remap the reduced 7,429-line Timeline facade, emphasizing transition integrity
orchestration and activity normalization.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline Cadence-import policy extraction.

Status:
Implementation published in `26437371`; focused and broad proof is green.

Selected boundary:
Move accepted Cadence-import extraction, invalidity checks, review-context
construction, issue precedence, external-ID/trust-boundary validation, and
invalid-context removal into `Timeline.CadenceImportPolicy`. `Timeline` retains
five private entry points used by row/context construction and operational
action policy. Shared stable-ID validation and invalid-shape encoding are
supplied as callbacks.

Why this slice:
The extraction moved 13 clauses into a 96-line internal module and reduced
Timeline from 7,705 to 7,663 lines. The five private facade entry points
preserve all row/context and operational-action callers.

Completed proof:
- Focused Cadence-import examples: 4 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,723 files.
- Canonical AST equivalence: all 13 moved clauses after normalizing only the
  five facade names and two callback boundaries.
- Format, whitespace, ownership, exactly-five-facade, unchanged Timeline public
  definitions, and xref checks passed.
- Independent read-only review found no findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline Cadence-import policy extraction, selected in `f0f49209` and
implemented in `26437371`.

Next candidate:
Remap the reduced 7,663-line Timeline facade, emphasizing transition integrity
gating and invalid-activity construction.

Blocked:
No.

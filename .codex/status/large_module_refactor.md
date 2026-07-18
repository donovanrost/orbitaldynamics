# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline operational action policy extraction.

Status:
Implementation published in `be206e7e`; focused and broad proof is green.

Selected boundary:
Move Cadence-import status classification, required operator-action precedence,
and command-review policy into `Timeline.OperationalActionPolicy`. `Timeline`
retains two private entry points used by row construction. Terminal/executed
status lists are supplied as selection data; the seven existing status/import/
lock/provider evidence helpers are supplied as callbacks. Operational-kind
inference remains Timeline-owned because its command-direction clause uses the
shared compile-time guard list also surfaced by capabilities.

Why this slice:
The extraction moved three clauses into an 86-line internal module and reduced
Timeline from 7,752 to 7,705 lines. The corrected boundary preserves all 11
Timeline-owned operational-kind clauses and their compile-time direction guard.

Completed proof:
- Focused operational-action examples: 6 passed.
- Full Timeline suite: 127 passed.
- Timeline schema-contract suites: 36 passed.
- Strict warnings-as-errors compile: 3,722 files.
- Canonical AST equivalence: all three moved clauses after normalizing only the
  two facade names and selection-data/callback boundaries.
- Format, whitespace, ownership, exactly-two-facade, unchanged Timeline public
  definitions, unchanged operational-kind clauses, and xref checks passed.
- Independent read-only review found no findings.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline operational action policy extraction, selected in `eea68690`, boundary
corrected in `4d37d6f3`, and implemented in `be206e7e`.

Next candidate:
Remap the reduced 7,705-line Timeline facade, emphasizing transition integrity
gating and Cadence-import validation.

Blocked:
No.

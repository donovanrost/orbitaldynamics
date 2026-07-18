# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline invalid lifecycle-state input policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move optional lifecycle-state input conversion, invalid-row detection and
aggregation, invalid/valid state identity access, and planned-before-realized
display identity into `Timeline.InvalidLifecycleStateInputPolicy`. `Timeline`
retains nine private entry points. Activity conversion, activity/timeline ID,
and sorted-unique helpers cross the boundary as callbacks.

Why this slice:
The reduced Timeline facade is 6,767 lines. These 17 exclusive clauses own the
invalid-input semantics shared by status, approval, and combined lifecycle
state artifacts. The boundary preserves optional nil behavior, existing invalid
rows, conversion error rows, invalid-row order, and planned identity priority.

Planned proof:
- Focused status, approval, and combined lifecycle-state examples, including
  malformed activity input and invalid count/reason/identity surfaces.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all 17 moved clauses after normalizing only the
  nine facade names and callback boundaries.
- Format, diff, whitespace, ownership, exactly-nine-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline lifecycle-transition assembly policy extraction, initially selected as
vocabulary in `da906798`, corrected in `0e098fb0`, implemented in `4717aadf`,
and handed off in `6b275dff`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing remaining
activity normalization and lifecycle state assembly.

Blocked:
No.

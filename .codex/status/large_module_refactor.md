# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline transition-helper integrity policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move opt-in transition-helper selected-activity validation, structured
integrity error construction, and status/approval/lifecycle raising policy into
`Timeline.TransitionHelperIntegrityPolicy`. `Timeline` retains private entry
points for validation and the three helper-specific raisers. Integrity
annotation/detection, selected projection/reason, list normalization, and map
compaction are supplied as callbacks.

Why this slice:
The reduced Timeline facade is 7,429 lines. These eight exclusive clauses form
one helper-integrity responsibility shared by status, approval, and lifecycle
APIs. Keeping structured error construction beside raising policy preserves
the exact selected-integrity versus transition-error messages.

Planned proof:
- Focused Timeline tests for reusable transitions, safe/unsafe status and
  approval application, and opt-in lifecycle selected-integrity gating.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all eight moved clauses after normalizing only
  the four facade names and callback boundaries.
- Format, diff, whitespace, ownership, exactly-four-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline selected-integrity policy extraction, selected in `135fa967`,
implemented in `90858060`, and handed off in `08b3a86a`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing transition
integrity orchestration and activity normalization.

Blocked:
No.

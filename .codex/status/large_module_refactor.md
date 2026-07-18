# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline transition-application activity policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move nil/non-nil transition-application activity normalization and preservation
of existing transition-application provenance into
`Timeline.TransitionApplicationActivityPolicy`. `Timeline` retains two private
entry points; activity normalization crosses the boundary explicitly.

Why this slice:
The 6,268-line Timeline facade still owns three exclusive clauses that govern
transition-application activity normalization and provenance carry-forward.
Moving them together isolates nil behavior, normalization dispatch, exact
provenance-map matching, and no-op fallback without extracting transition
selection or integrity coordinators.

Planned proof:
- Focused transition application and helper-provenance examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all three moved clauses after normalizing only
  public/private heads and the activity normalization callback.
- Format, diff, whitespace, ownership, exactly-two-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline protection-summary policy extraction, selected in `3d551921`,
implemented in `ac9421ae`, and handed off in `a5af2b2e`.

Next candidate:
Continue remapping the reduced Timeline facade after this slice, avoiding wide
report and activity-context map coordinator callback surfaces.

Blocked:
No.

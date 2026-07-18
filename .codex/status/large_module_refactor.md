# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline transition-application policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move the complete transition-application selection and provenance construction
cluster into `Timeline.TransitionApplicationPolicy`: seven selection clauses,
selected-activity provenance carry-forward, provenance construction, and
no-change reason policy. `Timeline` retains two private facade entry points for
selection and provenance attachment. The shared `compact_map/1` behavior is
supplied as one callback.

Why this slice:
The reduced Timeline facade is 7,930 lines. This approximately 95-line cluster
has one cohesive application-selection responsibility, 13 exclusive clauses,
and only one shared behavior dependency. Its two facade entry points preserve
all current single, batch, lifecycle, and integrity-gating callers.

Planned proof:
- Focused Timeline tests for direct transition selection, batch selection,
  helper-produced provenance, and provenance carry-forward.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all 13 moved clauses after normalizing only the
  two facade names and `compact_map/1` callback boundary.
- Format, diff, whitespace, ownership, exactly-two-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline provider-result policy extraction, selected in `63d6d709` and
implemented in `6778bbcd`, with handoff published in `4d52c1fd`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing operational
action classification and lifecycle-state decision policy.

Blocked:
No.

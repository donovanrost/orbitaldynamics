# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline invalid-activity row extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move deterministic invalid-activity row construction and invalid activity-ID
fallback policy into `Timeline.InvalidActivityRow`. `Timeline` retains one
private `invalid_activity_input_row/3` facade used by normalization. Shared
stable-ID validation, integrity-issue construction, and map compaction are
supplied as callbacks.

Why this slice:
The reduced Timeline facade is 7,663 lines. These three exclusive clauses form
an approximately 55-line invalid-row responsibility with no callers outside
the one facade. The boundary preserves stable source IDs, atom IDs, deterministic
reason/sequence fallbacks, and the complete review/integrity artifact shape.

Planned proof:
- Focused Timeline tests for invalid batch inputs, out-of-range activity
  context, and single invalid activity normalization.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all three moved clauses after normalizing only
  the facade name and three callback boundaries.
- Format, diff, whitespace, ownership, exactly-one-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline Cadence-import policy extraction, selected in `f0f49209`, implemented
in `26437371`, and handed off in `a706cc1a`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing transition
integrity gating and invalid-activity validation.

Blocked:
No.

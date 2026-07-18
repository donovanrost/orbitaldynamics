# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity-timing policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move activity start, end, explicit duration, and derived duration selection into
`Timeline.ActivityTimingPolicy`. `Timeline` retains three private entry points.
The boundary has no callbacks, module attributes, or shared vocabulary
arguments.

Why this slice:
The reduced Timeline facade is 6,609 lines. These four exclusive clauses own
the canonical-versus-alternate start/end precedence, explicit numeric duration
precedence, and numeric derived-duration fallback used across row, context,
throughput, uncertainty, and transition surfaces.

Planned proof:
- Focused explicit/alternate timing, numeric-string normalization, derived
  duration, throughput, and transition examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all four moved clauses after normalizing only
  the three facade names.
- Format, diff, whitespace, ownership, exactly-three-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline artifact-value encoding policy extraction, finalized in selection
correction `82527298`, implemented in `0a12b3ee`, and handed off in
`c235b248`.

Next candidate:
Remap the reduced Timeline facade after this slice, avoiding boundaries whose
guard vocabularies remain shared with Timeline.

Blocked:
No.

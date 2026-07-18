# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity numeric-value policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move numeric triplet conversion, scalar numeric parsing, and three-dimensional
vector norm into `Timeline.ActivityNumericValuePolicy`. `Timeline` retains
three private entry points. The boundary has no callbacks, module attributes,
or shared vocabulary arguments.

Why this slice:
The reduced Timeline facade is 6,396 lines. These seven exclusive clauses own
number/string parsing, exact triplet validation, invalid-value rejection, and
Euclidean norm behavior reused by numeric normalization, activity field
selection, execution uncertainty, and context assembly.

Planned proof:
- Focused number/string timing, numeric context, valid/invalid uncertainty
  triplets, vector norm, link-quality, and thermal examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all seven moved clauses after normalizing only
  the three facade names.
- Format, diff, whitespace, ownership, exactly-three-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity numeric-normalization policy extraction, selected in
`c0138e37`, implemented in `9eb1ad8d`, and handed off in `3c11945a`.

Next candidate:
Remap the reduced Timeline facade after this slice, avoiding the wide
activity-to-map coordinator callback surface.

Blocked:
No.

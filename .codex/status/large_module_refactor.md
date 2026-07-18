# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline activity numeric-normalization policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move the exclusive numeric activity-field vocabulary, canonical/alternate time
normalization, and optional numeric-field conversion/deletion into
`Timeline.ActivityNumericNormalizationPolicy`. `Timeline` retains two private
entry points; numeric parsing crosses the boundary explicitly. The per-field
helper becomes internal to the policy.

Why this slice:
The reduced Timeline facade is 6,528 lines. These three exclusive clauses and
their field vocabulary own numeric string conversion, invalid numeric field
removal, canonical time precedence, and alternate time fallback used by the
activity conversion coordinator. The vocabulary has no other Timeline
consumer.

Planned proof:
- Focused canonical/alternate timing, numeric-string context, throughput,
  link-quality, thermal, and invalid-number removal examples.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all three moved clauses after normalizing only
  the two facade names, numeric callback, and attribute relocation.
- Format, diff, whitespace, vocabulary ownership, exactly-two-facade, unchanged
  Timeline public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity row-alias policy extraction, selected in `b443c84e`,
implemented in `da390b5d`, and handed off in `39f033b8`.

Next candidate:
Remap the reduced Timeline facade after this slice, avoiding the wide
activity-to-map coordinator callback surface.

Blocked:
No.

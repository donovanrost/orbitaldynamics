# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline contact-direction normalization policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move activity direction normalization, provider alias resolution, canonical
direction membership, and direction token normalization into
`Timeline.ContactDirectionNormalizationPolicy`. `Timeline` retains the private
activity-normalization and capability-alias entry points plus the two existing
public `normalize_contact_direction/1` clauses. The non-string encoder crosses
the boundary explicitly.

Why this slice:
The reduced Timeline facade is 6,944 lines. These seven clauses own direction
normalization from raw activity input through provider aliases and canonical
MissionPlan capability values. The boundary preserves the public helper and
capability-map surfaces.

Planned proof:
- Focused Timeline capability and direction-normalization examples covering
  nil/empty, atoms, provider aliases, canonical values, and unknown tokens.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all seven moved clauses after normalizing only
  the four facade names and encoder callback.
- Format, diff, whitespace, ownership, exactly-four-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity-boolean policy extraction, selected in `25604047`, corrected
in `20e122b9`, implemented in `787e5732`, and handed off in `6cd27a69`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing remaining
activity normalization and lifecycle application.

Blocked:
No.

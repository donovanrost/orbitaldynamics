# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline artifact-value encoding policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move recursive map/list key stringification, scalar artifact-value encoding,
and nil-only map compaction into `Timeline.ArtifactValueEncodingPolicy`.
`Timeline` retains three private entry points. The boundary has no callbacks or
shared vocabulary arguments.

Why this slice:
The reduced Timeline facade is 6,615 lines. These eight exclusive clauses own
the common output-value semantics used across report, context, transition, and
summary assembly: recursive key/value normalization, boolean and nil
preservation, atom encoding, scalar pass-through, and removal of nil map
values. The operational-kind boundary was rejected before implementation
because its command-direction vocabulary is also owned by Timeline row
semantics and public row classification.

Planned proof:
- Focused nested atom-key/value, boolean, nil, list, scalar, and compact-map
  examples through operational rows, activity contexts, and transition state.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all eight moved clauses after normalizing only
  the three facade names.
- Format, diff, whitespace, ownership, exactly-three-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline activity-field value policy extraction, selected in `d7da8e84`,
implemented in `37b9114f`, and handed off in `e3890899`.

Next candidate:
Remap the reduced Timeline facade after this slice; lifecycle-category and
operational-kind extraction both require explicit compile-time vocabulary
ownership decisions.

Blocked:
No.

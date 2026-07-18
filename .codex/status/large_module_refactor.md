# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline cadence-import normalization policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move cadence-import alias canonicalization into the existing
`Timeline.CadenceImportPolicy`. `Timeline` retains the single normalization
entry point used by `activity_to_map/1` and supplies its shared
`put_new_present/3` helper as a callback.

Why this slice:
The reduced Timeline facade is 7,175 lines. These five exclusive clauses own
provider alias removal and first-present selection for external ID, activity
type, schema contract, and trust boundary. Extending the existing policy keeps
normalization and validation for the same embedded artifact together.

Planned proof:
- Focused Timeline examples for provider-shaped aliases and malformed non-map
  cadence-import evidence.
- Full Timeline and Timeline schema-contract suites.
- Strict warnings-as-errors compile.
- Canonical AST equivalence for all five moved clauses after normalizing only
  the single facade name and callback boundary.
- Format, diff, whitespace, ownership, exactly-one-facade, unchanged Timeline
  public-definition, and xref checks.
- Independent read-only review before publication.

Behavior/schema changes:
None intended. No schema-generation boundary is selected, so export
regeneration should not be required.

Last completed slice:
Timeline station-calendar status normalization policy extraction, selected in
`b1e680a8`, implemented in `86c63a95`, and handed off in `f0b88744`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing activity
normalization and lifecycle application.

Blocked:
No.

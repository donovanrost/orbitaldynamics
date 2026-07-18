# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline source-window normalization policy extraction.

Status:
Selection recorded; implementation has not started.

Selected boundary:
Move direct and metadata-nested source-window normalization plus exclusive
window ID/type lookup into `Timeline.SourceWindowNormalizationPolicy`.
`Timeline` retains the single normalization entry point used by
`activity_to_map/1` and supplies its shared `put_new_present/3` helper as a
callback.

Why this slice:
The reduced Timeline facade is 7,108 lines. These five exclusive clauses own
source-window shape precedence, metadata lifting, and window ID/type alias
priority. The boundary leaves the shared present-value helper and downstream
source-window context derivation in Timeline.

Planned proof:
- Focused Timeline examples for direct source windows and metadata-nested
  provider source-window provenance.
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
Timeline cadence-import normalization policy extraction, selected in
`44fc87fa`, implemented in `913b9fb5`, and handed off in `2c2bd82c`.

Next candidate:
Remap the reduced Timeline facade after this slice, emphasizing activity
normalization and lifecycle application.

Blocked:
No.

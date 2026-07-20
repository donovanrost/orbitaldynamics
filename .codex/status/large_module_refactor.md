# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline-transition validation direct routing.

Status:
Completed and pushed.

Selected boundary:
Remove the Schema facade's two one-hop wrappers for selected timeline-integrity
fields and optional timeline-integrity source rows.
Route the six callback-map entries directly to
`TimelineTransitionValidation.validate_selected_timeline_integrity_fields/3`
and `validate_optional_timeline_integrity_source_row/3`.
Keep callback-map composition, transition validators that need facade-owned
callbacks, contract routing, and all public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,178 lines.
- The two wrappers only forward the same three arguments and add no guards,
  defaults, callbacks, path adaptation, or result transformation.
- Six callback entries across Cadence-import, Cadence-source-review, and
  operator-review maps can capture the existing owner APIs directly.
- Exact callback arity/timing, issue ordering, paths/messages, validation
  results, and checked-in schema exports must remain unchanged.

Implementation:
Removed the two one-hop Schema wrappers and routed all six callback-map
entries directly to their TimelineTransitionValidation owner APIs.
`schema.ex` moved from 6,178 to 6,165 lines.

Verification:
- Strict focused Cadence-import/Cadence-row/operator-review/timeline/
  validation baseline before routing: 19 passed.
- The same strict focused suite after routing: 19 passed.
- Strict adjacent JSON Schema export/candidate-refresh/campaign-repair
  coverage: 17 passed.
- Strict full schema-export task: 1 passed.
- `mix xref callers
  OrbitalDynamics.Schema.TimelineTransitionValidation` reports
  `lib/orbital_dynamics/schema.ex (runtime)`.
- Static search confirms both wrapper definitions and all indirect captures
  are gone from `schema.ex`.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `4771bc80` pushed to `main`.

Behavior/schema changes:
None. Public facades, callback arity/timing, issue ordering, paths/messages,
validation behavior, and checked-in exports remain unchanged.

Last completed slice:
Schema timeline-transition validation direct routing, selected in `dcad3750`
and implemented in `4771bc80`.
`schema.ex` moved from 6,178 to 6,165 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

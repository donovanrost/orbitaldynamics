# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline-transition validation direct routing.

Status:
Selected; implementation not started.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema command-window capability-context extraction, selected in `63633755`
and implemented in `db23798a`.
`schema.ex` moved from 6,181 to 6,178 lines; the dedicated
CommandWindowCapabilityContext owner is 9 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

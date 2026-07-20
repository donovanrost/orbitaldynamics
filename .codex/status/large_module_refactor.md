# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema candidate-rejection source-row validation direct routing.

Status:
Selected; implementation not started.

Selected boundary:
Remove the Schema facade's one-hop optional candidate-rejection source-row
wrapper.
Route its two callback-map entries directly to
`CandidateRejectionValidation.validate_optional_source_row/3`.
Keep callback-map composition, report validators that add registry/model-limit
context, contract routing, and all public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,154 lines.
- The wrapper only forwards the same three arguments and adds no guards,
  defaults, callbacks, path adaptation, or result transformation.
- Two callback entries across Cadence-import and Cadence-source-review maps can
  capture the existing owner API directly.
- Exact callback arity/timing, issue ordering, paths/messages, validation
  results, and checked-in schema exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema operator-review row-link validation direct routing, selected in
`eb558891` and implemented in `0781f88b`.
`schema.ex` moved from 6,157 to 6,154 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

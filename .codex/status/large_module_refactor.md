# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema decision-support source-row validation direct routing.

Status:
Selected; implementation not started.

Selected boundary:
Remove the Schema facade's one-hop optional branch-comparison source-row
wrapper.
Route its three callback-map entries directly to
`DecisionSupportValidation.validate_optional_branch_comparison_source_row/3`.
Keep callback-map composition, optional report validators that build
facade-owned contract callbacks, contract routing, and all public facades in
`OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,165 lines.
- The wrapper only forwards the same three arguments and adds no guards,
  defaults, callbacks, path adaptation, or result transformation.
- Three callback entries across Cadence-import, Cadence-source-review, and
  operator-review maps can capture the existing owner API directly.
- Exact callback arity/timing, issue ordering, paths/messages, validation
  results, and checked-in schema exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema timeline-transition validation direct routing, selected in `dcad3750`
and implemented in `4771bc80`.
`schema.ex` moved from 6,178 to 6,165 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

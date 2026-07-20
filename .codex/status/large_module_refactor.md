# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema optional policy-escalation validation direct routing.

Status:
Selected; implementation not started.

Selected boundary:
Remove the Schema facade's one-hop optional policy-escalation validation
wrapper.
Route its three callback-map captures directly to
`PolicyValidation.validate_optional_escalation/4`.
Keep callback-map composition, policy validators that add facade-owned model
limits/field groups, and all public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,092 lines.
- The wrapper forwards the same four arguments to PolicyValidation and adds no
  guards, defaults, callbacks, path adaptation, or result transformation.
- Three callback maps can capture the existing owner API directly.
- Exact callback arity/timing, issue ordering, paths/messages, validation
  results, and checked-in schema exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema lifecycle-transition direct routing, selected in `347b1be9` and
implemented in `6ec944a7`.
`schema.ex` moved from 6,100 to 6,092 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

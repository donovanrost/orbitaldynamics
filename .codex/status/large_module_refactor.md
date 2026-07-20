# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema execution-metric validation direct routing.

Status:
Selected; implementation not started.

Selected boundary:
Remove the Schema facade's one-hop optional actual-data-rate throughput
derivation validator.
Route its two callback-map captures directly to
`ExecutionMetricContracts.validate_optional_actual_data_rate_throughput_derivation/4`.
Keep callback-map composition, contact-allocation/operator-review validation,
and all public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,089 lines.
- The wrapper and owner have the exact same four-argument `when is_map(map)`
  guard, and the wrapper adds no defaults, callbacks, path adaptation, or
  result transformation.
- Two callback maps can capture the existing owner API directly.
- Exact callback arity/timing, issue ordering, paths/messages, validation
  results, and checked-in schema exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema optional policy-escalation validation direct routing, selected in
`04ccebf0` and implemented in `d62e1c35`.
`schema.ex` moved from 6,092 to 6,089 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

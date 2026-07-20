# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema execution-metric validation direct routing.

Status:
Completed and pushed.

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
Removed the identically guarded optional throughput-derivation validation
wrapper and routed both callback-map captures directly to
ExecutionMetricContracts.
`schema.ex` moved from 6,089 to 6,079 lines.

Verification:
- Strict focused contact-allocation/operator-review/Cadence-import/
  validation-evidence baseline before routing: 17 passed.
- The same strict focused suite after routing: 17 passed.
- Strict adjacent JSON Schema export/Cadence-row/contact-feedback/
  fixture-visibility coverage: 22 passed.
- Strict full schema-export task: 1 passed.
- `mix xref callers OrbitalDynamics.Schema.ExecutionMetricContracts` reports
  the expected `schema.ex` caller alongside the domain contract callers.
- Static search confirms the wrapper definition and both indirect captures are
  gone.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `3e214a0f` pushed to `main`.

Behavior/schema changes:
None. Public facades, guard behavior, callback arity/timing, issue ordering,
paths/messages, validation behavior, and checked-in exports remain unchanged.

Last completed slice:
Schema execution-metric validation direct routing, selected in `9026057f` and
implemented in `3e214a0f`.
`schema.ex` moved from 6,089 to 6,079 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

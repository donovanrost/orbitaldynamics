# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema throughput-derivation direct routing.

Status:
Selected; implementation not started.

Selected boundary:
Remove the Schema facade's one-hop single and plural actual-data-rate
throughput-derivation schema helpers.
Route their one eager value call and six callback captures directly to the
same-arity TimelineContextJsonSchema owner APIs.
Keep report/row schema composition, callback-map ownership, and all public
facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,106 lines.
- Both helpers call same-arity TimelineContextJsonSchema owner APIs and add no
  guards, defaults, transformation, or caching.
- Their seven consumers can call/capture the owner directly while retaining
  current eager or lazy evaluation semantics.
- Exact throughput-derivation schemas, callback timing, generated JSON Schema,
  validation results, and checked-in exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema candidate-diff semantic-details direct routing, selected in `61665a3f`
and implemented in `aae28f78`.
`schema.ex` remains 6,106 lines while the intermediary helper is gone.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

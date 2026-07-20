# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema lifecycle-transition direct routing.

Status:
Selected; implementation not started.

Selected boundary:
Remove the Schema facade's one-hop lifecycle-transition schema helper.
Route its eager value call and eight callback captures directly to
`TimelineContextJsonSchema.lifecycle_transition/0`.
Keep timeline/report/row schema composition, callback-map ownership, and all
public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,100 lines.
- The helper calls the same-arity TimelineContextJsonSchema owner API and adds
  no guards, defaults, transformation, or caching.
- Its nine consumers can call/capture the owner directly while retaining
  current eager or lazy evaluation semantics.
- Exact lifecycle-transition schema, callback timing, generated JSON Schema,
  validation results, and checked-in exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema throughput-derivation direct routing, selected in `5b3a8b2e` and
implemented in `50c2ce24`.
`schema.ex` moved from 6,106 to 6,100 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema candidate-diff semantic-details direct routing.

Status:
Selected; implementation not started.

Selected boundary:
Remove the Schema facade's one-hop semantic-change-details schema helper.
Route its one eager value call and three callback-map captures directly to
`CandidateDiffJsonSchema.semantic_change_details/0`.
Keep strategy/Cadence/operator schema composition, callback-map ownership, and
all public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,106 lines.
- The helper calls the same-arity CandidateDiffJsonSchema owner API and adds no
  guards, defaults, transformation, or caching.
- Its four consumers can call/capture the owner directly while retaining their
  current eager or lazy evaluation semantics.
- Exact semantic-details schema, callback timing, generated JSON Schema,
  validation results, and checked-in exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema common assumptions direct routing, selected in `af5fc3cd` and
implemented in `aaacd9cd`.
`schema.ex` moved from 6,114 to 6,106 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

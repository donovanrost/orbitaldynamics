# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema candidate-diff semantic-details direct routing.

Status:
Completed and pushed.

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
Removed the one-hop semantic-change-details helper and routed the eager
strategy value plus all three callback-map captures directly to
CandidateDiffJsonSchema.
`schema.ex` remains 6,106 lines because the explicit owner captures offset the
removed helper.

Verification:
- Strict focused Cadence-import/Cadence-row/operator-review/strategy/export
  baseline before routing: 24 passed.
- The same strict focused suite after routing: 24 passed.
- Strict full schema-export task plus adjacent candidate-refresh,
  campaign-repair, and fixture-visibility coverage: 13 passed.
- `mix xref callers OrbitalDynamics.Schema.CandidateDiffJsonSchema` reports
  the expected `schema.ex` and CandidateRefreshPropertyDispatch callers.
- Static inspection confirms the facade helper definition is gone and all four
  consumers route directly to the owner.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `aae28f78` pushed to `main`.

Behavior/schema changes:
None. Public facades, eager/lazy evaluation timing, semantic-details schema,
generated JSON Schema, validation behavior, and checked-in exports remain
unchanged.

Last completed slice:
Schema candidate-diff semantic-details direct routing, selected in `61665a3f`
and implemented in `aae28f78`.
`schema.ex` remains 6,106 lines while the intermediary helper is gone.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

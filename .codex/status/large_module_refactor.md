# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema throughput-derivation direct routing.

Status:
Completed and pushed.

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
Removed the one-hop single/plural throughput-derivation schema helpers and
routed the eager value plus all six callback captures directly to
TimelineContextJsonSchema.
`schema.ex` moved from 6,106 to 6,100 lines.

Verification:
- Strict focused contact-allocation/contact-feedback/candidate-refresh/
  Cadence-row/export baseline before routing: 39 passed.
- The same strict focused suite after routing: 39 passed.
- Strict full schema-export task plus adjacent communications,
  operator-review, Cadence-import, and fixture-visibility coverage: 16 passed.
- `mix xref callers OrbitalDynamics.Schema.TimelineContextJsonSchema` reports
  `lib/orbital_dynamics/schema.ex (runtime)`.
- Static inspection confirms both helper definitions are gone and all seven
  consumers route directly to the owner.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `50c2ce24` pushed to `main`.

Behavior/schema changes:
None. Public facades, eager/lazy evaluation timing, throughput-derivation
schemas, generated JSON Schema, validation behavior, and checked-in exports
remain unchanged.

Last completed slice:
Schema throughput-derivation direct routing, selected in `5b3a8b2e` and
implemented in `50c2ce24`.
`schema.ex` moved from 6,106 to 6,100 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

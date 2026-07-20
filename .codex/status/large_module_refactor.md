# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema resource-projection assumptions direct routing.

Status:
Completed and pushed.

Selected boundary:
Remove the Schema facade's one-hop resource-projection assumptions helper.
Route the report property-dispatch callback directly to
`ResourceProjectionReportJsonSchema.assumptions/0`.
Keep property dispatch, row/flow schema construction, validation, and all
public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,068 lines.
- The helper calls the same-arity ResourceProjectionReportJsonSchema owner API
  and adds no guards, defaults, transformation, or caching.
- Its only consumer can capture the owner directly with unchanged lazy
  evaluation.
- Exact assumptions values and ordering, generated JSON Schema, validation
  results, and checked-in exports must remain unchanged.

Implementation:
Removed the one-hop resource-projection assumptions helper and routed the
property-dispatch callback directly to ResourceProjectionReportJsonSchema.
`schema.ex` moved from 6,068 to 6,065 lines.

Verification:
- Strict focused resource/filter/export baseline before routing: 22 passed.
- The same strict focused suite after routing: 22 passed.
- Strict full schema-export task plus adjacent candidate-refresh provenance,
  fixture-visibility, and validation coverage: 5 passed.
- `mix xref callers
  OrbitalDynamics.Schema.ResourceProjectionReportJsonSchema` reports the
  expected `schema.ex` and ResourceProjectionPropertyDispatch callers.
- Static search confirms the facade helper definition and indirect capture are
  gone.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `35553807` pushed to `main`.

Behavior/schema changes:
None. Public facades, lazy callback timing, assumptions values and ordering,
generated JSON Schema, validation behavior, and checked-in exports remain
unchanged.

Last completed slice:
Schema resource-projection assumptions direct routing, selected in `3d0e062a`
and implemented in `35553807`.
`schema.ex` moved from 6,068 to 6,065 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

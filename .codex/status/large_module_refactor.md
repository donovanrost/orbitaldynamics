# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema relay-data-path assumptions direct routing.

Status:
Completed and pushed.

Selected boundary:
Remove the Schema facade's one-hop relay-data-path assumptions helper.
Route the report property-dispatch callback directly to
`RelayDataPathSummaryJsonSchema.assumptions/0`.
Keep property dispatch, relay row schema construction, validation, and all
public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,065 lines.
- The helper calls the same-arity RelayDataPathSummaryJsonSchema owner API
  and adds no guards, defaults, transformation, or caching.
- Its only consumer can capture the owner directly with unchanged lazy
  evaluation.
- Exact assumptions values and ordering, generated JSON Schema, validation
  results, and checked-in exports must remain unchanged.

Implementation:
Removed the one-hop relay-data-path assumptions helper and routed the
property-dispatch callback directly to RelayDataPathSummaryJsonSchema.
`schema.ex` moved from 6,065 to 6,061 lines.

Verification:
- Strict focused communications/export baseline before routing: 27 passed.
- The same strict focused suite after routing: 27 passed.
- Strict full schema-export task plus adjacent candidate-refresh provenance,
  fixture-visibility, and validation coverage: 5 passed.
- `mix xref callers
  OrbitalDynamics.Schema.RelayDataPathSummaryJsonSchema` reports the expected
  `schema.ex` and StandaloneCommunicationsPropertyDispatch callers.
- Static search confirms the facade helper definition and indirect capture are
  gone.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `1d20cd05` pushed to `main`.

Behavior/schema changes:
None. Public facades, lazy callback timing, assumptions values and ordering,
generated JSON Schema, validation behavior, and checked-in exports remain
unchanged.

Last completed slice:
Schema relay-data-path assumptions direct routing, selected in `ba6c7206` and
implemented in `1d20cd05`.
`schema.ex` moved from 6,065 to 6,061 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

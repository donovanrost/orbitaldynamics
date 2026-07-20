# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema common assumptions direct routing.

Status:
Completed and pushed.

Selected boundary:
Remove the Schema facade's one-hop boolean-constant and string-constant
assumptions helpers.
Route the two timeline-preservation callers and the lazy timeline-activity
callback directly to CommonJsonSchema.
Keep preservation contract selection, assumption input values, property
dispatch, and all public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,114 lines.
- Both helpers forward their only argument to same-arity CommonJsonSchema
  owner APIs without guards, defaults, or transformation.
- The string helper has two preservation callers; the boolean helper has one
  lazy property-dispatch callback.
- Exact assumption keys/values and ordering, lazy callback timing, generated
  JSON Schema, validation results, and checked-in exports must remain
  unchanged.

Implementation:
Removed the one-hop boolean/string assumptions helpers and routed both
timeline-preservation callers plus the lazy timeline-activity callback
directly to CommonJsonSchema.
`schema.ex` moved from 6,114 to 6,106 lines.

Verification:
- Strict focused timeline-activity/operational-timeline/contact-feedback/
  export baseline before routing: 31 passed.
- The same strict focused suite after routing: 31 passed.
- Strict full schema-export task plus adjacent timeline-summary,
  campaign-repair, and fixture-visibility coverage: 20 passed.
- `mix xref callers OrbitalDynamics.Schema.CommonJsonSchema` includes the
  expected `schema.ex (runtime)` caller.
- Static search confirms both facade helper definitions and all indirect calls
  are gone.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `aaacd9cd` pushed to `main`.

Behavior/schema changes:
None. Public facades, lazy callback timing, assumption keys/values and
ordering, generated JSON Schema, validation behavior, and checked-in exports
remain unchanged.

Last completed slice:
Schema common assumptions direct routing, selected in `af5fc3cd` and
implemented in `aaacd9cd`.
`schema.ex` moved from 6,114 to 6,106 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

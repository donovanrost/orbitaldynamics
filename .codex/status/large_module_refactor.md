# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema lifecycle-transition direct routing.

Status:
Completed and pushed.

Selected boundary:
Remove the Schema facade's one-hop lifecycle-transition schema helper.
Route its eager value call and nine callback captures directly to
`TimelineContextJsonSchema.lifecycle_transition/0`.
Keep timeline/report/row schema composition, callback-map ownership, and all
public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,100 lines.
- The helper calls the same-arity TimelineContextJsonSchema owner API and adds
  no guards, defaults, transformation, or caching.
- Its ten consumers can call/capture the owner directly while retaining
  current eager or lazy evaluation semantics.
- Exact lifecycle-transition schema, callback timing, generated JSON Schema,
  validation results, and checked-in exports must remain unchanged.

Implementation:
Removed the one-hop lifecycle-transition schema helper and routed the eager
value plus all nine callback captures directly to TimelineContextJsonSchema.
Added a local TimelineContextJsonSchema alias and mechanically normalized the
facade's existing references to that owner so direct routing remains compact.
`schema.ex` moved from 6,100 to 6,092 lines.

Verification:
- Strict focused timeline-activity/contact-feedback/Cadence-row/
  Cadence-import/export baseline before routing: 34 passed.
- After correcting one initially missed, uncommitted operator-review capture,
  the same strict focused suite passed 34.
- Strict full schema-export task plus adjacent operator-review,
  operational-timeline, contact-allocation, candidate-refresh, and
  fixture-visibility coverage: 24 passed.
- `mix xref callers OrbitalDynamics.Schema.TimelineContextJsonSchema` reports
  `lib/orbital_dynamics/schema.ex (runtime)`.
- Static inspection confirms the helper definition and all indirect calls are
  gone.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `6ec944a7` pushed to `main`.

Behavior/schema changes:
None. Public facades, eager/lazy evaluation timing, lifecycle-transition
schema, generated JSON Schema, validation behavior, and checked-in exports
remain unchanged.

Last completed slice:
Schema lifecycle-transition direct routing, selected in `347b1be9` and
implemented in `6ec944a7`.
`schema.ex` moved from 6,100 to 6,092 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

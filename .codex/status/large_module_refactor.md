# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema common string-array callback routing.

Status:
Completed and pushed.

Selected boundary:
Route the 34 lazy `string_array_schema/0` callbacks in Schema directly to
`CommonJsonSchema.string_array/0`. Keep the facade helper and its ten eager
consumers unchanged for a separate slice. Preserve callback timing, property
provider keys, all public Schema APIs, generated JSON Schema, executable
validation, and checked-in exports.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 5,986 lines; the other
  targeted public facades are now 164 to 524 lines.
- The string-array helper calls the same zero-arity CommonJsonSchema owner API
  without facade state, guards, defaults, transformation, or caching.
- Exact token counting finds 34 lazy captures and ten eager calls; this slice
  intentionally changes only the captures.
- Exact string-array schemas, callback timing, composed schemas, validation,
  and checked-in exports must remain unchanged.

Implementation:
Routed all 34 lazy string-array callbacks directly to CommonJsonSchema while
retaining the facade helper and all ten eager calls. Formatting kept
`schema.ex` at 5,986 lines.

Verification:
- Strict focused export/communications/feedback/Cadence/review baseline before
  routing: 34 passed.
- The same strict focused suite after routing: 34 passed.
- Strict checked-in export, timeline-report, resource, and handoff coverage:
  21 passed.
- The full schema-export task completed and produced no checked-in changes.
- Exact static counts confirm 34 direct owner captures, zero indirect captures,
  and ten retained eager facade calls.
- `mix xref callers OrbitalDynamics.Schema.CommonJsonSchema` reports the
  expected facade and internal schema-owner consumers.
- `git diff --check` passed.
- Strict forced compile passed across 4,070 files.
- Implementation commit `3f3d0363` pushed to `main`.

Behavior/schema changes:
None. Public Schema APIs, property-provider keys, callback timing,
string-array schemas, composed schemas, executable validation, and checked-in
exports remain unchanged.

Last completed slice:
Schema common string-array callback routing, selected in `cc4ba93d` and
implemented in `3f3d0363`.
`schema.ex` remains 5,986 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

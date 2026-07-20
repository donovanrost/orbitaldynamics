# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema common string-array eager routing.

Status:
Completed and pushed.

Selected boundary:
Route the ten remaining eager `string_array_schema/0` calls in Schema directly
to `CommonJsonSchema.string_array/0`, then remove the now-unused facade helper.
Keep the 34 lazy callbacks routed directly to the owner as completed in the
previous slice. Preserve property-provider keys, all public Schema APIs,
generated JSON Schema, executable validation, and checked-in exports.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 5,986 lines; the other
  targeted public facades are now 164 to 524 lines.
- The prior slice left exactly ten eager calls behind the same zero-arity
  pass-through helper, with no facade state, guards, defaults, transformation,
  or caching.
- Removing the final one-hop helper completes this narrow ownership cleanup
  without broadening into context-bearing Schema helpers.
- Exact string-array schemas, provider maps, composed schemas, validation, and
  checked-in exports must remain unchanged.

Implementation:
Routed all ten eager string-array schema reads directly to CommonJsonSchema and
removed the now-unused one-hop facade helper. The 34 lazy owner callbacks from
the preceding slice remain unchanged. `schema.ex` moved from 5,986 to 5,982
lines.

Verification:
- Strict focused export/communications/feedback/Cadence/review baseline before
  routing: 34 passed.
- The same strict focused suite after routing: 34 passed.
- Strict checked-in export, timeline-report, resource, and handoff coverage:
  21 passed.
- The full schema-export task completed and produced no checked-in changes.
- Exact static counts confirm ten direct eager owner calls, 34 direct lazy
  owner callbacks, and zero remaining facade helper references.
- `mix xref callers OrbitalDynamics.Schema.CommonJsonSchema` reports the
  expected facade and internal schema-owner consumers.
- `git diff --check` passed.
- Strict forced compile passed across 4,070 files.
- Implementation commit `568cff53` pushed to `main`.

Behavior/schema changes:
None. Public Schema APIs, property-provider keys, callback timing,
string-array schemas, composed schemas, executable validation, and checked-in
exports remain unchanged.

Last completed slice:
Schema common string-array eager routing, selected in `b6a13f21` and
implemented in `568cff53`.
`schema.ex` moved from 5,986 to 5,982 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters. Preserve
the context-bearing CommonJsonSchema wrappers unless a separate exact
ownership boundary is proven.

Blocked:
No.

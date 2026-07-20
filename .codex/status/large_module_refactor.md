# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema common string-array callback routing.

Status:
Selected; implementation not started.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
CampaignPlanner repair orchestration extraction, selected in `13845591` and
implemented in `b94e90b1`.
`campaign_planner.ex` moved from 502 to 164 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

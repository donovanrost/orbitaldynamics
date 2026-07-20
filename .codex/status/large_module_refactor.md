# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema provider-counteroffer model ownership.

Status:
Selected; implementation not started.

Selected boundary:
Move the provider-counteroffer report model enum from the Schema facade into
`OrbitalDynamics.Schema.ProviderCounterofferReportJsonSchema`.
Route ProviderCounterofferPropertyDispatch's model callback directly to that
owner.
Keep provider-counteroffer property dispatch, row/summary schema construction,
validation, and all public facades in their current modules.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,140 lines.
- The four-value enum is used only as the `models` callback for
  ProviderCounterofferReportJsonSchema property construction.
- That report schema already interprets and emits the enum, making it the
  cohesive owner for this schema-facing metadata.
- Exact model values and ordering, callback timing, generated JSON Schema,
  validation results, and checked-in exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema station-calendar model-context consolidation, selected in `e6cebc64`
and implemented in `26a3fd42`.
`schema.ex` moved from 6,141 to 6,140 lines; the station-calendar capability
context moved from 21 to 23 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

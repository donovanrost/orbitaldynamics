# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema provider-counteroffer model ownership.

Status:
Completed and pushed.

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
Moved the four provider-counteroffer report model values into
ProviderCounterofferReportJsonSchema and routed the property-dispatch callback
directly to that owner.
`schema.ex` moved from 6,140 to 6,131 lines; the report schema owner moved from
105 to 114 lines.

Verification:
- Strict focused provider-counteroffer/station-provider/export baseline before
  move: 22 passed.
- The same strict focused suite after move: 22 passed.
- Strict full schema-export task plus adjacent communications/report-fixture/
  fixture-visibility coverage: 14 passed.
- `mix xref callers
  OrbitalDynamics.Schema.ProviderCounterofferReportJsonSchema` reports the
  expected `schema.ex` and ProviderCounterofferPropertyDispatch callers.
- Static search confirms the facade model function and indirect capture are
  gone.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `16d36516` pushed to `main`.

Behavior/schema changes:
None. Public facades, callback timing, model values and ordering, generated
JSON Schema, validation behavior, and checked-in exports remain unchanged.

Last completed slice:
Schema provider-counteroffer model ownership, selected in `d997b385` and
implemented in `16d36516`.
`schema.ex` moved from 6,140 to 6,131 lines; the provider-counteroffer report
schema owner moved from 105 to 114 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

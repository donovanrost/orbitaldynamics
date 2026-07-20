# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema validation-acceptance metadata direct routing.

Status:
Selected; implementation not started.

Selected boundary:
Remove the Schema facade's one-hop safety-case count-fields helper.
Route the candidate-refresh property-dispatch callback directly to
`ValidationAcceptanceReportContracts.safety_case_count_fields/0`.
Keep candidate-refresh property dispatch, validation-acceptance algorithms,
and all public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,071 lines.
- The helper calls the same-arity ValidationAcceptanceReportContracts owner API
  and adds no guards, defaults, transformation, or caching.
- Its only consumer can capture the owner directly with unchanged lazy
  evaluation.
- Exact count-field values and ordering, generated JSON Schema, validation
  results, and checked-in exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema policy field-group direct routing, selected in `f7dd8526` and
implemented in `67722532`.
`schema.ex` moved from 6,079 to 6,071 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema policy field-group direct routing.

Status:
Selected; implementation not started.

Selected boundary:
Remove the Schema facade's one-hop policy context and action-rule field-group
helpers.
Route their three eager consumers directly to
`PolicyFieldGroups.json_schema/0` and `PolicyFieldGroups.action_rule/0`.
Keep policy schema/validation composition, model-limit routing, and all public
facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,079 lines.
- Both helpers call same-arity PolicyFieldGroups owner APIs and add no guards,
  defaults, transformation, or caching.
- Two schema consumers and one validation consumer can call the owner
  directly.
- Exact field-group values and ordering, generated JSON Schema, validation
  results, and checked-in exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema execution-metric validation direct routing, selected in `9026057f` and
implemented in `3e214a0f`.
`schema.ex` moved from 6,089 to 6,079 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

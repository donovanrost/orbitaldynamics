# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema policy field-group direct routing.

Status:
Completed and pushed.

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
Removed the one-hop policy context/action-rule field-group helpers and routed
both schema consumers plus the validation consumer directly to
PolicyFieldGroups.
`schema.ex` moved from 6,079 to 6,071 lines.

Verification:
- Strict focused policy/contact-feedback/validation-policy/export baseline
  before routing: 22 passed.
- The same strict focused suite after routing: 22 passed.
- Strict full schema-export task plus adjacent campaign-plan,
  contact-allocation, and fixture-visibility coverage: 12 passed.
- `mix xref callers OrbitalDynamics.Schema.PolicyFieldGroups` reports the
  expected `schema.ex` and ContactIntentContracts callers.
- Static search confirms both facade helper definitions and all indirect calls
  are gone.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `67722532` pushed to `main`.

Behavior/schema changes:
None. Public facades, field-group values and ordering, generated JSON Schema,
validation behavior, and checked-in exports remain unchanged.

Last completed slice:
Schema policy field-group direct routing, selected in `f7dd8526` and
implemented in `67722532`.
`schema.ex` moved from 6,079 to 6,071 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

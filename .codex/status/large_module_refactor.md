# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema policy rule-match field-group direct routing.

Status:
Completed and pushed.

Selected boundary:
Remove the zero-context, one-hop policy rule-match field-group helper. Route
the three approval-requirement, policy-decision, and rule-match validation
calls directly to `PolicyFieldGroups.rule_match/0`. Keep validation sequencing,
model limits, error paths, all other policy validation, and all public facades
in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,031 lines.
- The helper calls the same zero-arity PolicyFieldGroups owner API and adds no
  facade state, guards, defaults, transformation, or caching.
- Its three eager consumers can call the owner directly with unchanged
  evaluation ordering.
- Exact field groups, validation issues and ordering, error paths, generated
  JSON Schema, and checked-in exports must remain unchanged.

Implementation:
Removed the policy rule-match field-group helper and routed all three eager
validation consumers directly to PolicyFieldGroups. `schema.ex` moved from
6,031 to 6,027 lines.

Verification:
- Strict focused policy schema/runtime baseline before routing: 90 passed.
- The same strict focused suite after routing: 90 passed.
- Strict validation-policy, full JSON Schema export-contract, and checked-in
  export coverage: 19 passed.
- The full schema-export task completed and produced no checked-in changes.
- `mix xref callers OrbitalDynamics.Schema.PolicyFieldGroups` reports the
  expected `schema.ex` and ContactIntentContracts consumers.
- Static search confirms the helper definition and all indirect calls are gone.
- `git diff --check` passed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `7c7a7079` pushed to `main`.

Behavior/schema changes:
None. Public facades, field groups, validation sequencing, issues and error
paths, generated JSON Schema, and checked-in exports remain unchanged.

Last completed slice:
Schema policy rule-match field-group direct routing, selected in `e2bd180e`
and implemented in `7c7a7079`.
`schema.ex` moved from 6,031 to 6,027 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

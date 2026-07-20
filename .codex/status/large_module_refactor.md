# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema policy rule-match field-group direct routing.

Status:
Selected; implementation not started.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema handoff leaf-property direct routing, selected in `fcc99445` and
implemented in `df84fb51`.
`schema.ex` moved from 6,039 to 6,031 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.

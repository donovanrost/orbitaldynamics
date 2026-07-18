# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema policy artifact property-dispatch extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move JSON-property dispatch/context assembly for policy bundle, policy decision,
and approval requirement into an internal
`Schema.PolicyArtifactPropertyDispatch` owner.

Why this slice:
`Schema` is 7,755 lines. These three policy contracts share action-rule,
decision-match, escalation, approval-context, and policy-limit dependencies but
still route directly through the facade.

Current coupling/problem:
The facade owns nine policy context dependencies and focused fallback routing
across two adjacent clauses plus the separated approval-requirement clause.

Public facade to preserve:
All `Schema` APIs; the three JSON Schema documents; checked-in exports,
deterministic ordering, focused fallback behavior, lazy provider order, and all
errors.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/policy_artifact_property_dispatch.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The three clauses pass compact dependencies to the new owner; named contexts
and focused fallback routing move out of `Schema`; focused policy/strategy/
export tests pass; strict compile, full byte-clean schema regeneration, and
independent review are clean.

Verification gaps:
- Focused baseline, strict compile, export proof, and independent review remain.

Tests run:
- None yet for this selected slice.

Behavior/schema changes:
None intended.

Last completed slice:
Strategy artifact schema dispatch published as implementation `abbd645d` and
handoff `59b9667c`: focused 21/21, strict 3,662-file compile, full byte-clean
schema regeneration, and independent review passed.

Next candidate:
After this slice, remap the remaining direct property clauses in `Schema`.

Blocked:
No.

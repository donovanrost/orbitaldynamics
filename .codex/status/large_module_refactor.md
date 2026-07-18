# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema planning-analysis model property-dispatch extension.

Status:
Slice selected; selection publication pending.

Selected slice:
Move focused JSON-property routing/context assembly for optimizer contract and
Monte Carlo reproducibility report into the existing internal
`Schema.PlanningAnalysisPropertyDispatch` owner.

Why this slice:
`Schema` is 7,736 lines. Only four direct focused clauses remain, and these two
model/reproducibility contracts fit the existing planning-analysis owner.

Current coupling/problem:
The facade owns optimizer contract/pattern context and Monte Carlo
contract/pattern/model-limit/vector context plus focused fallback routing.

Public facade to preserve:
All `Schema` APIs; both JSON Schema documents; checked-in exports,
deterministic ordering, focused fallback behavior, provider order and arity,
and all errors.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/planning_analysis_property_dispatch.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
Both clauses pass compact dependencies to the existing owner; named contexts
and focused fallback routing move out of `Schema`; focused optimizer/
reproducibility/export tests pass; strict compile, full byte-clean schema
regeneration, and independent review are clean.

Verification gaps:
- Focused baseline, strict compile, export proof, and independent review remain.

Tests run:
- None yet for this selected slice.

Behavior/schema changes:
None intended.

Last completed slice:
Planning-reference schema dispatch published as implementation `b4b57709` and
handoff `9c0f2ae2`: focused 36/36, strict 3,667-file compile, full byte-clean
schema regeneration, and independent review passed.

Next candidate:
Extend the existing schema-validation and timeline-report owners for the final
schema-migration and candidate-rejection direct clauses.

Blocked:
No.

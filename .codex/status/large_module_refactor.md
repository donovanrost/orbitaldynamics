# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema planning-analysis model property-dispatch extension.

Status:
Implementation published as `fba3dc77`; handoff publication pending.

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
- None for this slice. Full checked-in schema regeneration is byte-identical.
- Independent review was clean. No API, schema, export, ordering,
  error-behavior, ownership, or behavioral finding remains.

Tests run:
- Baseline and post-change focused optimizer/reproducibility/export subset:
  22 passed with warnings as errors.
- Strict forced compile: 3,667 files clean with warnings as errors.
- Full schema export regenerated every checked-in schema and bundle with zero
  diff.
- Public `Schema` definitions match selection commit `4a0594d6`; xref reports
  the dispatcher has only the `Schema` runtime caller.
- Format, changed-file whitespace, and `git diff --check` passed.
- Independent review confirmed exact constants/provider order and arities,
  unchanged existing owner functions and neighboring routes, then reran all
  proof clean.

Behavior/schema changes:
None intended.

Outcome:
Optimizer contract and Monte Carlo reproducibility routes now delegate to the
existing `PlanningAnalysisPropertyDispatch`. Implementation published as
`fba3dc77`.

Last completed slice:
Planning-reference schema dispatch published as implementation `b4b57709` and
handoff `9c0f2ae2`: focused 36/36, strict 3,667-file compile, full byte-clean
schema regeneration, and independent review passed.

Next candidate:
Extend the existing schema-validation and timeline-report owners for the final
schema-migration and candidate-rejection direct clauses.

Blocked:
No.

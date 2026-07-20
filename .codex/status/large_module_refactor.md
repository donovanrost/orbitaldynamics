# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema decision-support registered-contract validation routing.

Status:
Completed and pushed.

Selected boundary:
Add owner-default required and optional entry points to
DecisionSupportValidation for objective tradeoff, objective satisfaction,
branch comparison, ranking comparison, optimizer contract, and score-term
report artifacts. Derive requirements from the existing objective-analysis and
optimization registries, route direct and optional Schema consumers to the
owner, and remove the six facade closures plus the shared registered-contract
wrapper. Keep every customizable optional-validation API.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 5,294 lines; the other
  targeted public facades are now 164 to 524 lines.
- Six direct validation clauses duplicate registry requirements and dedicated
  contract-owner routing already available outside Schema.
- The same six artifacts use facade-local optional closures from campaign plan,
  campaign repair, or campaign strategy callback graphs.
- Objective-analysis and optimization registry modules own all required-field
  lists needed by the six default entry points.
- Dedicated contract modules own all artifact-specific validation; no callback
  needs recursive Schema lookup or another facade-local validator.
- The existing arity-three optional APIs remain the customization boundary.

Implementation:
Added owner-default required and optional validators for all six selected
artifacts to DecisionSupportValidation. Required validators derive field lists
from the objective-analysis or optimization registries and route to the
dedicated contract owners; optional validators reuse the existing customizable
arity-three APIs. Routed all direct and campaign callback consumers to the
owner and removed six facade closures plus the registered-contract wrapper.
`schema.ex` moved from 5,294 to 5,202 lines.

Verification:
- Strict optimizer/campaign baseline before routing: 6 passed.
- The same strict focused suite after routing: 6 passed.
- Strict optimizer, campaign, policy, Cadence, candidate-refresh, and
  operator-review coverage: 204 passed.
- Strict schema and JSON Schema export coverage: 18 passed.
- The full schema-export task completed and produced no checked-in changes.
- Exact static inspection confirms every selected direct and optional consumer
  routes to DecisionSupportValidation and zero selected facade closures remain.
- `mix xref callers OrbitalDynamics.Schema.DecisionSupportValidation` reports
  only the expected Schema, CadenceImportValidation, and
  OperatorReviewValidation runtime callers.
- `mix format --check-formatted` and `git diff --check` passed.
- Strict forced compile passed across 4,073 files with no warnings.
- Bounded local review confirmed registry requirements, issue ordering and
  paths match the former direct and optional facade routes.
- Implementation commit `0d29fbd9` pushed to `main`.

Behavior/schema changes:
None. Required fields, validation ordering and paths, customizable optional
APIs, public Schema APIs, validation results, and checked-in exports remain
unchanged.

Last completed slice:
Schema decision-support registered-contract validation routing, selected in
`8da19f67` and implemented in `0d29fbd9`.
`schema.ex` moved from 5,294 to 5,202 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters. Preserve
the context-bearing CommonJsonSchema wrappers unless a separate exact
ownership boundary is proven.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema decision-support registered-contract validation routing.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, validation ordering and paths, customizable
optional APIs, public Schema APIs, validation results, and checked-in exports
must remain unchanged.

Last completed slice:
Schema Cadence-import validation context extraction, selected in `3f6438ff` and
implemented in `e4d9f571`.
`schema.ex` moved from 5,475 to 5,294 lines.

Next candidate:
Implement and verify the selected decision-support registered-contract routing,
then re-rank the remaining non-capability Schema responsibility clusters.

Blocked:
No.

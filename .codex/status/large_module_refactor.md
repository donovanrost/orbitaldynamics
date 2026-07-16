# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: plan change registry extraction.

Status:
Published.

Selected slice:
Moved `candidate_rejection_report.v1` and `plan_delta.v1` into
`Schema.PlanChangeRegistryContracts`.

Why this slice:
The adjacent definitions describe candidate rejection and concrete plan change,
with shared planned/realized activity dependencies and focused contract tests.

Current coupling/problem:
Declarative plan-change contract data remains embedded in the large
public `Schema` facade even though the facade only needs the merged registry.

Public facade to preserve:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Likely extraction target:
`OrbitalDynamics.Schema.PlanChangeRegistryContracts.contracts/0`.

Likely files:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/plan_change_registry_contracts.ex`

Likely tests:
- `test/orbital_dynamics/schema/candidate_rejection_contracts_test.exs`
- `test/orbital_dynamics/schema/campaign_plan_contracts_test.exs`
- `test/orbital_dynamics/schema/campaign_repair_strategy_contracts_test.exs`
- `test/orbital_dynamics/schema/registry_capability_test.exs`
- `test/mix/tasks/orbital_dynamics.schema.export_test.exs`

Definition of done:
The definitions live in the focused internal registry, the facade merges that
registry, focused validation/export tests pass, and the exact contracts/bundle
fingerprint remains unchanged.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/plan_change_registry_contracts.ex`

Public APIs preserved:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Behavior/schema changes:
None. Registry contents, plan-change validation, and generated schemas retain the
baseline fingerprint.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Candidate rejection, campaign plan, campaign repair/strategy, fixture
  visibility, registry capability, and schema export tests passed: 15 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref caller and compile-connected checks passed with the expected facade edge.
- Formatting, whitespace, new-file no-index, and checked-in-schema cleanliness
  checks passed.

Verification gaps:
- The full suite was not run for this declarative extraction.

Last commit:
`17b6cb19` (`Extract plan change registry contracts`).

Next candidate:
Assess timeline feedback report, timeline activity state, and precondition
summary as the next bounded registry family.

Blocked:
No.

Notes:
- `schema.ex` decreased from 17,528 to 17,474 lines.
- `PlanChangeRegistryContracts` is 63 lines.
- Parent review found no must-fix findings; parent publishing is the active-mode
  fallback because subagent delegation is unavailable.
- The inline registry remains substantial; this is not a completion claim.

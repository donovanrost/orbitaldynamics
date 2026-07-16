# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: proposed-contact registry extraction.

Status:
Ready to publish.

Selected slice:
Move the proposed-contact contract into
`Schema.ProposedContactRegistryContracts`.

Why this slice:
The ledger-named definition is a distinct Cadence-facing row contract with
direct validation/schema assertions, fixture visibility, campaign-plan nesting,
registry checks, and export coverage.

Current coupling/problem:
Declarative proposed-contact data remains embedded in the
large public `Schema` facade even though it can be merged as a focused registry.

Public facade to preserve:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Likely extraction target:
`OrbitalDynamics.Schema.ProposedContactRegistryContracts.contracts/0`.

Likely files:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/proposed_contact_registry_contracts.ex`

Likely tests:
- `test/orbital_dynamics/schema/cadence_row_contracts_test.exs`
- `test/orbital_dynamics/schema/fixture_visibility_contracts_test.exs`
- `test/orbital_dynamics/schema/campaign_plan_contracts_test.exs`
- `test/orbital_dynamics/schema/registry_capability_test.exs`
- `test/mix/tasks/orbital_dynamics.schema.export_test.exs`

Definition of done:
The definition lives in the focused internal registry, the facade merges that
registry, focused validation/visibility/nesting/export tests pass, and the exact
contracts/bundle fingerprint remains unchanged.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/proposed_contact_registry_contracts.ex`

Public APIs preserved:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Behavior/schema changes:
None. Registry contents, proposed-contact validation, and generated schemas
retain the baseline fingerprint.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Cadence-row validation/schema, fixture visibility, campaign-plan nesting,
  registry capability, and schema export tests passed: 13 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref caller and compile-connected checks passed with the expected facade edge.
- Formatting, whitespace, new-file review, and checked-in-schema cleanliness
  checks passed.

Verification gaps:
- The full suite was not run for this declarative extraction.

Last commit:
`82867816` (`Extract contact intent registry contracts`).

Next candidate:
Assess the adjacent activity-template contract as the next bounded registry
extraction.

Blocked:
No.

Notes:
- `schema.ex` decreased from 15,227 to 15,202 lines.
- `ProposedContactRegistryContracts` is 34 lines.
- Parent review found no must-fix findings; parent publishing is the active-mode
  fallback because subagent delegation is unavailable.
- The inline registry remains substantial; this is not a completion claim.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: contact-intent registry extraction.

Status:
Published.

Selected slice:
Move the contact-intent and contact-intent summary contracts into
`Schema.ContactIntentRegistryContracts`.

Why this slice:
The adjacent definitions form one complete nested communications family with
direct summary fixtures, approval-schema coverage, Cadence-row validation,
registry checks, and export assertions.

Current coupling/problem:
Declarative contact-intent and summary data remain embedded in the
large public `Schema` facade even though it can be merged as a focused registry.

Public facade to preserve:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Likely extraction target:
`OrbitalDynamics.Schema.ContactIntentRegistryContracts.contracts/0`.

Likely files:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/contact_intent_registry_contracts.ex`

Likely tests:
- `test/orbital_dynamics/schema/communications_contracts_test.exs`
- `test/orbital_dynamics/schema/contact_feedback_contracts_test.exs`
- `test/orbital_dynamics/schema/cadence_row_contracts_test.exs`
- `test/orbital_dynamics/schema/registry_capability_test.exs`
- `test/mix/tasks/orbital_dynamics.schema.export_test.exs`

Definition of done:
The definitions live in the focused internal registry, the facade merges that
registry, focused validation/approval/summary/export tests pass, and the exact
contracts/bundle fingerprint remains unchanged.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/contact_intent_registry_contracts.ex`

Public APIs preserved:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Behavior/schema changes:
None. Registry contents, contact-intent validation, and generated schemas retain
the baseline fingerprint.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Contact-intent summary fixtures, approval schemas, Cadence-row validation,
  registry capability, and schema export tests passed: 23 tests.
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
Assess the adjacent proposed-contact contract as the next bounded registry
extraction.

Blocked:
No.

Notes:
- `schema.ex` decreased from 15,298 to 15,227 lines.
- `ContactIntentRegistryContracts` is 80 lines.
- Parent review found no must-fix findings; parent publishing is the active-mode
  fallback because subagent delegation is unavailable.
- The inline registry remains substantial; this is not a completion claim.

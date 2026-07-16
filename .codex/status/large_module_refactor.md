# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: timeline feedback state registry extraction.

Status:
Ready to publish.

Selected slice:
Moved `timeline_feedback_report.v1`, `timeline_activity_state.v1`, and
`timeline_activity_precondition_summary.v1` into
`Schema.TimelineFeedbackStateRegistryContracts`.

Why this slice:
The adjacent definitions form a feedback-to-state chain plus its precondition
gate, with shared timeline state and export coverage.

Current coupling/problem:
Declarative timeline feedback/state contract data remains embedded in the large
public `Schema` facade even though the facade only needs the merged registry.

Public facade to preserve:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Likely extraction target:
`OrbitalDynamics.Schema.TimelineFeedbackStateRegistryContracts.contracts/0`.

Likely files:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_feedback_state_registry_contracts.ex`

Likely tests:
- `test/orbital_dynamics/schema/timeline_activity_state_contracts_test.exs`
- `test/orbital_dynamics/schema/timeline_summary_contracts_test.exs`
- `test/orbital_dynamics/schema/contact_feedback_contracts_test.exs`
- `test/orbital_dynamics/schema/registry_capability_test.exs`
- `test/mix/tasks/orbital_dynamics.schema.export_test.exs`

Definition of done:
The definitions live in the focused internal registry, the facade merges that
registry, focused validation/export tests pass, and the exact contracts/bundle
fingerprint remains unchanged.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_feedback_state_registry_contracts.ex`

Public APIs preserved:
- `OrbitalDynamics.Schema.contracts/0`
- `OrbitalDynamics.Schema.contract/1`
- `OrbitalDynamics.Schema.json_schema/1`
- `OrbitalDynamics.Schema.json_schema_bundle/0`
- `OrbitalDynamics.Schema.validate_artifact/2`

Behavior/schema changes:
None. Registry contents, timeline feedback/state validation, and generated
schemas retain the baseline fingerprint.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Timeline activity state, timeline summary, contact feedback, fixture
  visibility, registry capability, and schema export tests passed: 41 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref caller and compile-connected checks passed with the expected facade edge.
- Formatting, whitespace, new-file no-index, and checked-in-schema cleanliness
  checks passed.

Verification gaps:
- The full suite was not run for this declarative extraction.

Last commit:
`585bdd33` (`Update plan change handoff`).

Next candidate:
Assess realized activity and realized state snapshot as the next bounded registry
family.

Blocked:
No.

Notes:
- `schema.ex` decreased from 17,474 to 17,351 lines.
- `TimelineFeedbackStateRegistryContracts` is 134 lines.
- Parent review found no must-fix findings; parent publishing is the active-mode
  fallback because subagent delegation is unavailable.
- The inline registry remains substantial; this is not a completion claim.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: execution-metric callback ownership cleanup.

Status:
Published.

Selected slice:
Let `Schema.ExecutionMetricContracts` call primitive validation directly for
single/list throughput derivations and execution uncertainty.

Why this slice:
All four callbacks pointed to primitive support, and the three entry points form
one cohesive metric-validation family with no facade-specific state.

Current coupling/problem:
Resolved. Execution metrics own type/number/vector/error dependencies, and the
facade only delegates validation inputs.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Execution metric validation order and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/execution_metric_contracts.ex`

Behavior/schema changes:
None. Derivation/list/uncertainty checks execute in the same order.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Timeline report, campaign repair/strategy, cadence-row, and broad schema/
  resource/contact/export coverage passed: 103 tests.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref showed the facade runtime edge and sole dependency on primitive support.
- Formatting, whitespace, diff review, and checked-in-schema cleanliness passed.

Verification gaps:
- The full suite was not run for this internal cleanup.

Last commit:
`f6aeeacc` (`Collapse execution metric callbacks`).

Next candidate:
Assess protection-decision callback ownership and its remaining generic optional
field-equality helper.

Blocked:
No.

Notes:
- `schema.ex` decreased from 14,631 to 14,619 lines.
- `ExecutionMetricContracts` decreased from 132 to 80 lines.
- Parent review found no must-fix findings; parent publishing is the active-mode
  fallback because subagent delegation is unavailable.
- The facade remains substantial; this is not a completion claim.

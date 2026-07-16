# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: execution-report callback and status ownership cleanup.

Status:
Completed and published.

Selected slice:
Move execution statuses into the execution-report contract module and replace
its sixteen-callback facade bag with direct support/domain dependencies.

Why this slice:
Status values are report-family metadata already shared by runtime and nested
source-evidence validation; every other callback maps to existing support or
the existing result-artifact model-limit owner.

Current coupling/problem:
Resolved. Execution statuses are family-owned, result-artifact limits and
aggregation are direct dependencies, collection/stable-ID/primitive support is
called directly, and the facade only delegates artifacts.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Fixture/report/check order, derived status/counts, comparison errors,
  validation levels, and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/execution_report_contracts.ex`

Definition of done:
Execution statuses have one family-owned source, callback plumbing is gone,
focused execution/runtime/export tests and fingerprint pass, and xref shows
direct support and result-artifact dependencies.

Behavior/schema changes:
None. Execution statuses, model limits, failure rows, derived counts/status,
paths/messages, and deterministic schema output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Eighteen execution, result-artifact, validation-fixture, and export tests passed.
- Full checked-in schema export produced no diffs.
- Exact schema fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref shows the facade caller and direct result-artifact, aggregation,
  collection, primitive, and stable-ID dependencies.
- Formatting and `git diff --check` passed.

Verification gaps:
- Full suite not run; the focused eighteen-test execution/export gate and
  deterministic fingerprint are the verification boundary for this slice.

Last commit:
`a3a20434` (`Collapse execution report callbacks`).

Next candidate:
Collapse Monte Carlo reproducibility callback ownership; its capability limits
and duplicate-ID/list helpers all have existing direct owners.

Blocked:
No.

Notes:
- `schema.ex` is 14,317 lines after this slice (down from 14,343).
- `ExecutionReportContracts` is 193 lines and callback-free.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.
- Parent review/publishing is the active-mode fallback because subagent
  delegation is unavailable.

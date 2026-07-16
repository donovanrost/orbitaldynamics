# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Lint-contract callback ownership cleanup.

Status:
Complete and published.

Selected slice:
Replace campaign-request/study-manifest lint callback plumbing with direct
diagnostic, stable-ID, primitive, and collection validation dependencies.

Why this slice:
The diagnostic callback already delegates to `ValidationDiagnosticContracts`;
the list fallback is trivial and all remaining callbacks are shared support.

Result:
- Removed the thirteen-function facade bag and both callback arguments.
- The leaf now directly uses diagnostic, stable-ID, primitive, and collection
  validation and owns its two-clause list fallback.
- Preserved both lint pipelines, issue traversal, status/count logic, SHA checks,
  supported-code/output checks, and exact paths/messages.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/lint_contracts.ex`

Verification:
- `mix compile --warnings-as-errors` passed.
- Focused campaign-request lint, study-manifest lint, lint/strategy boundary,
  and schema-export tests passed: 6 tests, 0 failures, 179 excluded.
- Runtime probes preserved exact lowercase-SHA, duplicate-output, and
  unsupported-output paths/messages.
- Full schema export passed; checked-in schemas remained unchanged.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref shows the facade as the only lint caller and the leaf as a direct
  `ValidationDiagnosticContracts` caller.
- `mix format --check-formatted`, `git diff --check`, callback residue checks,
  and bounded diff review passed.

Verification gaps:
- Full suite not run; focused coverage was used for this behavior-preserving
  boundary cleanup.

Published implementation:
`248bf6db` (`Collapse lint contract callbacks`).

Size change:
- `schema.ex`: 13,693 -> 13,673 lines.
- `lint_contracts.ex`: 348 -> 308 lines.

Next candidate:
Validation-report callback ownership cleanup. Its issue/remediation callbacks
already route to `ValidationDiagnosticContracts`; statuses are fixed and model
limits come from `RegistryCapability`; all other callbacks are shared support.

Blocked:
No.

Notes:
- Validation-report focused fixtures cover both single and nested batch reports,
  including counts, statuses, model limits, and remediation.
- Approval-requirement validation was audited and deferred because it composes
  facade-owned activity-context, policy-rule-match, and escalation validators.
- Realized-state-snapshot and timeline-transition application rows remain
  deferred because they compose callback-driven nested validators.
- Quality/readiness gates, plan delta, campaign plan/strategy, activity context,
  and resource-projection flow rows remain deferred because their bags compose
  facade-owned contextual or nested artifact validation.

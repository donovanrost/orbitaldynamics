# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation-report callback ownership cleanup.

Status:
Complete and published.

Selected slice:
Replace single/batch schema-validation report callback plumbing with direct
diagnostic, registry-capability, primitive, and collection dependencies.

Why this slice:
Issue/remediation callbacks already delegate to `ValidationDiagnosticContracts`;
statuses are fixed, model limits come from `RegistryCapability`, and every
remaining callback is shared validation support.

Result:
- Removed the seventeen-function facade bag and both callback arguments.
- The leaf now directly uses diagnostic, registry-capability, primitive, and
  collection support; two now-dead facade diagnostic delegates were removed.
- Preserved nested report traversal, status/count derivation, model limits,
  remediation validation, validation order, and exact paths/messages.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/validation_report_contracts.ex`

Verification:
- `mix compile --warnings-as-errors` passed.
- Focused single-report, nested batch-report, validation-scoring, and schema
  export tests passed: 11 tests, 0 failures, 179 excluded.
- Runtime probes preserved exact status, model-limit, and nested status-count
  paths/messages (including the existing nil status message).
- Full schema export passed; checked-in schemas remained unchanged.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref shows the facade as the only report caller and the leaf as a direct
  `RegistryCapability` and `ValidationDiagnosticContracts` caller.
- `mix format --check-formatted`, `git diff --check`, callback residue checks,
  and bounded diff review passed.

Verification gaps:
- Full suite not run; focused coverage was used for this behavior-preserving
  boundary cleanup.

Published implementation:
`f77bc8a9` (`Collapse validation report callbacks`).

Size change:
- `schema.ex`: 13,673 -> 13,633 lines.
- `validation_report_contracts.ex`: 302 -> 232 lines.

Next candidate:
Manifest-field-reference callback ownership cleanup. Its seven callbacks are
all primitive validation; the cohesive leaf owns all field graph, enum,
top-level-required, activation-section, and array-item semantics.

Blocked:
No.

Notes:
- Manifest-field-reference focused fixtures exercise duplicate paths, derived
  field counts, required/activation references, enums, and row integrity.
- Approval-requirement validation was audited and deferred because it composes
  facade-owned activity-context, policy-rule-match, and escalation validators.
- Realized-state-snapshot and timeline-transition application rows remain
  deferred because they compose callback-driven nested validators.
- Quality/readiness gates, plan delta, campaign plan/strategy, activity context,
  and resource-projection flow rows remain deferred because their bags compose
  facade-owned contextual or nested artifact validation.

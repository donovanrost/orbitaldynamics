# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Study-benchmark callback ownership cleanup.

Status:
Complete and published.

Selected slice:
Replace the study-benchmark callback bag with direct schema-contract-field,
primitive, and collection validation dependencies.

Why this slice:
All twelve callbacks map to cohesive shared validation modules, and focused
fixture coverage exercises eight benchmark families plus stale derived counts.

Result:
- Removed the twelve-function callback bag, call-site callback argument, and the
  facade import that became unused.
- The leaf now directly uses `SchemaContractField`, primitive validation, and
  collection validation while preserving validation and traversal order.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/study_benchmark_contracts.ex`

Verification:
- `mix compile --warnings-as-errors` passed.
- Curated benchmark fixture and schema-export tests passed: 4 tests, 0 failures,
  180 excluded. The fixture test covers eight benchmark families.
- Runtime probes preserved exact scenario-count, trajectory-count, and
  repetitions mismatch paths/messages.
- Full schema export passed; checked-in schemas remained unchanged.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref shows the facade as the only runtime caller and the leaf as an explicit
  `SchemaContractField` consumer.
- `mix format --check-formatted`, `git diff --check`, callback residue checks,
  and bounded diff review passed.

Verification gaps:
- Full suite not run; focused coverage was used for this behavior-preserving
  boundary cleanup.

Published implementation:
`c7883e39` (`Collapse study benchmark callbacks`).

Size change:
- `schema.ex`: 13,712 -> 13,693 lines.
- `study_benchmark_contracts.ex`: 260 -> 202 lines.

Next candidate:
Lint-contract callback ownership cleanup. The diagnostic callback can route
directly to `ValidationDiagnosticContracts.validate_issue/3`; `list_value/2` is
a trivial local fallback; the remaining callbacks are shared validation.

Blocked:
No.

Notes:
- Approval-requirement validation was audited and deferred because it composes
  facade-owned activity-context, policy-rule-match, and escalation validators.
- Realized-state-snapshot and timeline-transition application rows remain
  deferred because they compose callback-driven nested validators.
- Quality/readiness gates, plan delta, campaign plan/strategy, activity context,
  and resource-projection flow rows remain deferred because their bags compose
  facade-owned contextual or nested artifact validation.

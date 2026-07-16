# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Realized-activity callback ownership cleanup.

Status:
Complete and published.

Selected slice:
Replace realized-activity callback plumbing with direct primitive, stable-ID,
execution-metric, and shared validation dependencies.

Why this slice:
Fourteen callbacks are shared validation support and execution uncertainty
already has a cohesive `ExecutionMetricContracts` API; metadata identity and
provider trust-boundary behavior are leaf-owned.

Result:
- Removed the sixteen-function facade bag and callback argument.
- The leaf now directly uses primitive/stable-ID validation and the cohesive
  execution-uncertainty API while retaining identity and provider-trust rules.
- Preserved field order, status, metadata identity, uncertainty, provider trust,
  stable IDs, probability/vector checks, and exact paths/messages.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/realized_activity_contracts.ex`

Verification:
- `mix compile --warnings-as-errors` passed.
- Full contact/operational-feedback contract coverage, curated realized-activity
  fixture, and schema-export tests passed: 9 tests, 0 failures, 180 excluded.
- Runtime probes preserved exact execution-uncertainty, missing external-ID,
  and missing trust-boundary paths/messages.
- Full schema export passed; checked-in schemas remained unchanged.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref shows facade/planned-activity callers and the leaf's direct
  `ExecutionMetricContracts` dependency.
- `mix format --check-formatted`, `git diff --check`, callback residue checks,
  and bounded diff review passed.

Verification gaps:
- Full suite not run; focused coverage was used for this behavior-preserving
  boundary cleanup.

Published implementation:
`1adf8d09` (`Collapse realized activity callbacks`).

Size change:
- `schema.ex`: 13,565 -> 13,543 lines.
- `realized_activity_contracts.ex`: 505 -> 431 lines.

Next candidate:
Operational-feedback callback ownership cleanup. With realized activity now a
direct cohesive leaf, its remaining three callbacks map directly to collection
validation, `RealizedActivityContracts`, and primitive errors.

Blocked:
No.

Notes:
- Operational-feedback map-shape/probability/string-list checks and nested
  realized activities are covered by the contact-feedback contract suite.
- Realized-activity focused fixtures cover identity objects, provider trust,
  uncertainty, vectors/probabilities, status, and derived metadata IDs.
- Starting point: `schema.ex` is 13,620 lines; optimizer-objective contracts are
  559 lines.
- Previous implementation commit: `206faab0`.
- Branch-event validation was audited and deferred because it composes semantic
  change, candidate-diff, safety-case, and other facade-owned validators.
- Approval-requirement validation was audited and deferred because it composes
  facade-owned activity-context, policy-rule-match, and escalation validators.
- Realized-state-snapshot and timeline-transition application rows remain
  deferred because they compose callback-driven nested validators.
- Quality/readiness gates, plan delta, campaign plan/strategy, activity context,
  and resource-projection flow rows remain deferred because their bags compose
  facade-owned contextual or nested artifact validation.

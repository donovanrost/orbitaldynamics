# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operational-feedback callback ownership cleanup.

Status:
Complete and published.

Selected slice:
Replace the operational-feedback three-function callback adapter with direct
collection, realized-activity, and primitive-error dependencies.

Why this slice:
Realized activity is now a cohesive direct leaf; the other two callbacks are
already-extracted optional-row traversal and primitive error construction.

Result:
- Removed the three-function facade bag and callback argument.
- Operational feedback now directly uses optional-row traversal, primitive
  errors, and `RealizedActivityContracts` for nested activities.
- Preserved optional/null behavior, map traversal/order, nested paths, map value
  constraints, and exact diagnostics.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/operational_feedback_contracts.ex`

Verification:
- `mix compile --warnings-as-errors` passed.
- Full contact/operational-feedback and schema-export suites passed: 8 tests.
- Runtime probes preserved exact probability-range and string-list-map
  paths/messages.
- Full schema export passed; checked-in schemas remained unchanged.
- SHA-256 over `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref confirms the facade-only operational-feedback entry point.
- `mix format --check-formatted`, `git diff --check`, callback residue checks,
  and bounded diff review passed.

Verification gaps:
- Full suite not run; focused coverage was used for this behavior-preserving
  boundary cleanup.

Published implementation:
`1ddfd48c` (`Collapse operational feedback callbacks`).

Size change:
- `schema.ex`: 13,543 -> 13,534 lines.
- `operational_feedback_contracts.ex`: 159 -> 151 lines.

Next candidate:
Realized-state-snapshot callback ownership cleanup. The formerly blocking nested
realized-activity validator is now a cohesive direct dependency; model limits
come from a public planner API and all remaining callbacks are shared support or
local frequency aggregation.

Blocked:
No.

Notes:
- Realized-state-snapshot focused fixtures cover nested activity validation,
  counts/statuses, IDs, assumptions, model limits, and checked-in exports.
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

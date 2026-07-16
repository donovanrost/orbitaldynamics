# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy-decision count callback ownership cleanup.

Status:
Complete and published.

Selected slice:
Replace the policy-decision count callback bag with direct equality/error
support.

Why this slice:
Both callbacks map to primitive support, with checked-in policy decisions
covering derived classification, counts, and escalation structure.

Current coupling/problem:
The facade assembles a two-function bag for a cohesive derived-count validator
that owns all of its policy-specific computation.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Fixture/report/check order, derived status/counts, comparison errors,
  validation levels, and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/policy_decision_count_contracts.ex`

Definition of done:
The facade bag and module wrappers are gone, focused policy/export tests and the
fingerprint pass, and xref shows a direct primitive dependency.

Behavior/schema changes:
None. Contact identity, intervals, timeline/source-window matching, model limits,
reservation metadata, paths/messages, and schema output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors`
- `mix test test/orbital_dynamics/schema/policy_contracts_test.exs:6 test/orbital_dynamics/schema_export_test.exs`
  (4 passed)
- `mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- Contract fingerprint:
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`
- `mix xref callers OrbitalDynamics.Schema.PolicyDecisionCountContracts`
- Focused xref graph for policy-decision counts
- `mix format --check-formatted`
- `git diff --check`

Verification gaps:
- Full suite not run.

Last commit:
`41116961` (`Collapse policy decision count callbacks`).

Next candidate:
Audit operational-readiness classification as the next small leaf; keep the
known mixed callback boundaries deferred.

Blocked:
No.

Notes:
- Starting point: `schema.ex` is 14,092 lines; policy-decision counts are 113
  lines.
- Ending point: `schema.ex` is 14,084 lines and policy-decision counts are 91
  lines.
- The generated schema export was byte-for-byte unchanged.
- Resource-projection flow-row was audited and deferred because source-window
  validation still composes candidate-diff-owned behavior.
- Campaign strategy was audited and deferred because it composes nested
  facade-owned validators rather than primitive-only support.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.

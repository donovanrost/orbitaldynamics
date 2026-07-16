# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy-bundle/action-rule callback ownership cleanup.

Status:
Complete and published.

Selected slice:
Replace the nested policy-bundle and action-rule callback bags with direct
primitive, collection, stable-ID, and model-limit support.

Why this slice:
All policy action-rule callbacks map to shared support, and the bundle's only
remaining dependencies are explicit model-limit and field-group data. Focused
policy tests cover valid fixtures, model-limit mismatch, and generated schema.

Current coupling/problem:
The facade assembles an eight-function bundle bag plus an eighteen-function
action-rule bag, even though neither contract module needs facade-owned behavior.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Fixture/report/check order, derived status/counts, comparison errors,
  validation levels, and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/policy_bundle_contracts.ex`
- `lib/orbital_dynamics/schema/policy_action_rule_contracts.ex`
- `lib/orbital_dynamics/schema/primitive_validation.ex`

Definition of done:
Both facade bags and callback wrappers are gone; focused policy/export tests,
the fingerprint, formatting, and export checks pass; xref shows direct shared
validation dependencies.

Behavior/schema changes:
None. Contact identity, intervals, timeline/source-window matching, model limits,
reservation metadata, paths/messages, and schema output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors` (passed).
- `mix test test/orbital_dynamics/policy_test.exs test/orbital_dynamics/schema/policy_contracts_test.exs test/orbital_dynamics/schema_export_test.exs`
  (93 passed).
- `mix test test/orbital_dynamics/validation_test.exs:8290 test/orbital_dynamics/validation_test.exs:8403 test/orbital_dynamics/validation_test.exs:8479`
  (3 passed, 178 excluded).
- `mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
  (passed; checked-in export unchanged).
- Contract fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Focused xref callers/graphs confirmed direct collection, primitive, stable-ID,
  and nested policy-action dependencies.
- `mix format --check-formatted` and `git diff --check` (passed).
- Bounded local review found no validation-order, guard, path/message, or shared
  helper drift; review sidecar delegation was unavailable under runtime policy.

Verification gaps:
- Full suite not run.

Last commit:
`d92b02cf` (`Collapse policy bundle callbacks`).

Next candidate:
Audit policy-decision nested ownership: its primitive/model-limit/count support
is now direct-capable, while rule-match and escalation validators remain the
explicit nested boundary.

Blocked:
No.

Notes:
- Starting point: `schema.ex` is 14,059 lines; policy bundle is 104 lines;
  policy action rules are 478 lines.
- Ending point: `schema.ex` is 13,984 lines; policy bundle is 77 lines; policy
  action rules are 356 lines. Shared primitive validation is 408 lines after
  receiving the unchanged 20-line optional exact-model-limit helper.
- The supported shared model-limit helper remains behaviorally identical; only
  its ownership moves from the facade to primitive validation.
- Published implementation commit: `d92b02cf`; the parent performed the exact
  mechanical commit/push because publisher delegation was unavailable under
  runtime policy.
- Resource-projection flow-row was audited and deferred because source-window
  validation still composes candidate-diff-owned behavior.
- Campaign strategy was audited and deferred because it composes nested
  facade-owned validators rather than primitive-only support.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.

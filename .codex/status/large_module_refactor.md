# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy-decision/rule-match callback ownership cleanup.

Status:
Complete and published.

Selected slice:
Replace the policy-decision and nested rule-match callback bags with direct
shared validation and explicit nested module delegation.

Why this slice:
Rule-match callbacks all map to shared support or the callback-free escalation
module. Decision-level callbacks likewise map to shared support, rule-match,
escalation, and the already extracted count validator.

Current coupling/problem:
The facade assembles a thirteen-function decision bag plus a thirteen-function
rule-match bag for cohesive internal modules with no facade-owned behavior.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Fixture/report/check order, derived status/counts, comparison errors,
  validation levels, and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/policy_decision_contracts.ex`
- `lib/orbital_dynamics/schema/policy_rule_match_contracts.ex`

Definition of done:
Both facade bags and callback wrappers are gone; focused policy/schema/export
tests, fingerprint, formatting, and export checks pass; xref shows the direct
shared and nested validation dependencies.

Behavior/schema changes:
None. Contact identity, intervals, timeline/source-window matching, model limits,
reservation metadata, paths/messages, and schema output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors` (passed after removing five facade imports
  made obsolete by the callback-bag removal).
- `mix test test/orbital_dynamics/policy_test.exs test/orbital_dynamics/schema/policy_contracts_test.exs test/orbital_dynamics/schema_export_test.exs`
  (93 passed).
- `mix test test/orbital_dynamics/validation_test.exs:8183`
  (1 passed, 180 excluded).
- `mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
  (passed; checked-in export unchanged).
- Contract fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Focused xref callers/graphs confirmed direct collection, primitive, stable-ID,
  count, escalation, and rule-match dependencies.
- `mix format --check-formatted` and `git diff --check` (passed).
- Bounded local review found no validation-order, guard, path/message, or nested
  delegation drift; review sidecar delegation was unavailable under runtime
  policy.

Verification gaps:
- Full suite not run.

Last commit:
`b4db6998` (`Collapse policy decision callbacks`).

Next candidate:
Remove the primitive/stable callback bag from resource-summary validation while
retaining its module-owned derived battery/storage margin checks.

Blocked:
No.

Notes:
- Starting point: `schema.ex` is 13,984 lines; policy decision is 125 lines;
  policy rule match is 237 lines.
- Ending point: `schema.ex` is 13,934 lines; policy decision is 65 lines; policy
  rule match is 145 lines.
- Policy escalation and policy-decision count validators are already
  callback-free and remain the explicit nested owners.
- Campaign-plan validation was audited and deferred because its bag composes
  more than twenty facade-owned nested artifact validators.
- Published implementation commit: `b4db6998`; the parent performed the exact
  mechanical commit/push because publisher delegation was unavailable under
  runtime policy.
- Resource-projection flow-row was audited and deferred because source-window
  validation still composes candidate-diff-owned behavior.
- Campaign strategy was audited and deferred because it composes nested
  facade-owned validators rather than primitive-only support.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Scoped downlink and candidate-refresh context callback ownership cleanup.

Status:
Complete and published.

Selected slice:
Replace the nested scoped-downlink and candidate-refresh context callback bags
with direct primitive/stable support and direct child composition.

Why this slice:
Both layers map entirely to existing support, and focused candidate/repair tests
cover invalid counts plus nested context fields.

Current coupling/problem:
The facade assembles separate bags for a primitive leaf and a thin extension
whose only family dependency is that same leaf.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Fixture/report/check order, derived status/counts, comparison errors,
  validation levels, and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/scoped_downlink_context_contracts.ex`
- `lib/orbital_dynamics/schema/candidate_refresh_scoped_context_contracts.ex`

Definition of done:
Both facade bags and module wrappers are gone, the extension calls the leaf
directly, focused nested/export tests and fingerprint pass, and xref shows the
intended primitive/stable dependency chain.

Behavior/schema changes:
None. Contact identity, intervals, timeline/source-window matching, model limits,
reservation metadata, paths/messages, and schema output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors`
- `mix test test/orbital_dynamics/schema/campaign_repair_strategy_contracts_test.exs:6 test/orbital_dynamics/schema/candidate_refresh_contracts_test.exs:999 test/orbital_dynamics/schema_export_test.exs`
  (5 passed, 10 excluded)
- `mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- Contract fingerprint:
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`
- `mix xref callers` for both scoped context modules
- Focused xref graphs for both scoped context modules
- `mix format --check-formatted`
- `git diff --check`

Verification gaps:
- Full suite not run.

Last commit:
`5a00dff6` (`Collapse scoped context callbacks`).

Next candidate:
Audit policy-decision count validation as the next primitive-only leaf; keep
resource-projection flow-row, campaign strategy, and activity context deferred.

Blocked:
No.

Notes:
- Starting point: `schema.ex` is 14,117 lines; scoped-downlink context is 106
  lines and its candidate-refresh extension is 89 lines.
- Ending point: `schema.ex` is 14,092 lines; scoped-downlink context is 74 lines
  and its candidate-refresh extension is 37 lines.
- The generated schema export was byte-for-byte unchanged.
- Resource-projection flow-row was audited and deferred because source-window
  validation still composes candidate-diff-owned behavior.
- Campaign strategy was audited and deferred because it composes nested
  facade-owned validators rather than primitive-only support.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.

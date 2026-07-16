# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Freshness-report callback ownership cleanup.

Status:
Complete and published.

Selected slice:
Replace freshness-report callbacks with direct primitive validation and move
its fixed `current`/`stale`/`unknown` status set into the cohesive leaf.

Why this slice:
All thirteen callbacks map to shared primitive support or the leaf's fixed
status vocabulary. Focused candidate-refresh contract coverage exercises valid
fixtures, derived counts/statuses, type errors, and JSON Schema export.

Current coupling/problem:
The facade assembles a thirteen-function bag for one optional freshness-report
entry point even though the leaf owns freshness-policy-derived semantics.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Fixture/report/check order, derived status/counts, comparison errors,
  validation levels, and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/freshness_report_contracts.ex`

Definition of done:
The facade bag and call-site callback argument are gone; focused candidate
refresh/schema export tests, fingerprint, formatting, and export checks pass;
xref shows direct primitive and CandidateRefresh model-limit dependencies.

Behavior/schema changes:
None intended. Required fields, policy-derived reasons/statuses, state-quality
classification, model limits, paths/messages, and schema output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors` (passed).
- `mix test test/orbital_dynamics/schema/candidate_refresh_contracts_test.exs:873 test/orbital_dynamics/schema/candidate_refresh_contracts_test.exs:999 test/orbital_dynamics/schema_export_test.exs`
  (5 passed, 8 excluded).
- Runtime fixture probes confirmed unchanged derived-status and stale-reason
  paths/messages; a top-level scalar probe was discarded because the public
  artifact validator intentionally accepts maps only.
- `mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
  (passed; checked-in export unchanged).
- Contract fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Focused xref callers confirmed direct primitive and CandidateRefresh
  model-limit dependencies and the facade-only freshness leaf entry point.
- `mix format --check-formatted` and `git diff --check` (passed).
- Bounded local review confirmed unchanged validation order, policy-derived
  reasons/statuses, state-quality classification, paths, and messages; review
  sidecar delegation was unavailable under runtime policy.

Verification gaps:
- Full suite not run.

Last commit:
`54bc2e8b` (`Collapse freshness report callbacks`).

Next candidate:
Remove the shared-validation callback bag from candidate-refresh window and
remaining-horizon contracts; its twelve callbacks map to primitive,
stable-ID, and collection-validation support.

Blocked:
No.

Notes:
- Starting point: `schema.ex` is 13,873 lines; freshness reports are 216 lines.
- Ending point: `schema.ex` is 13,854 lines; freshness reports are 168 lines.
- Published implementation commit: `54bc2e8b`.
- Quality-gate row and operational-readiness gate callbacks were audited and
  deferred because both compose facade-owned context and handoff validators.
- Plan-delta validation was audited and deferred because it composes facade-owned
  activity-context, timeline-link, uncertainty, and realized-activity validators.
- Campaign-plan validation was audited and deferred because its bag composes
  more than twenty facade-owned nested artifact validators.
- Resource-projection flow-row was audited and deferred because source-window
  validation still composes candidate-diff-owned behavior.
- Campaign strategy was audited and deferred because it composes nested
  facade-owned validators rather than primitive-only support.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.

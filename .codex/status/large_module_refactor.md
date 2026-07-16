# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline-identity-collision callback ownership cleanup.

Status:
Complete and published.

Selected slice:
Replace timeline-identity-collision field callbacks with direct primitive and
stable-ID support.

Why this slice:
All three callbacks map to existing support, with focused timeline-report tests
covering collision fields and invalid stable-ID lists.

Current coupling/problem:
The timeline-identity-collision validator receives optional type/count checks
and stable-ID-list validation through a facade-assembled keyword bag.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Fixture/report/check order, derived status/counts, comparison errors,
  validation levels, and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/policy_escalation_contracts.ex`

Definition of done:
Policy-escalation callback plumbing is gone, focused nested/export tests and
fingerprint pass, and xref shows direct primitive/stable-ID dependencies.

Behavior/schema changes:
None. Contact identity, intervals, timeline/source-window matching, model limits,
reservation metadata, paths/messages, and schema output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors`
- `mix test test/orbital_dynamics/schema/timeline_report_contracts_test.exs:501 test/orbital_dynamics/schema/timeline_report_contracts_test.exs:1091 test/orbital_dynamics/schema_export_test.exs`
  (5 passed, 6 excluded)
- `mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- Contract fingerprint:
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`
- `mix xref callers OrbitalDynamics.Schema.TimelineIdentityCollisionContracts`
- `mix xref graph --source lib/orbital_dynamics/schema/timeline_identity_collision_contracts.ex --format plain`
- `mix format --check-formatted`
- `git diff --check`

Verification gaps:
- Full suite not run.

Last commit:
`0ba7ec63` (`Collapse timeline collision callbacks`).

Next candidate:
Station-calendar contact-count callback ownership; keep mixed activity-context
deferred.

Blocked:
No.

Notes:
- Starting point: `schema.ex` is 14,162 lines.
- Ending point: `schema.ex` is 14,153 lines; the extracted validator is 35
  lines.
- The generated schema export was byte-for-byte unchanged.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.

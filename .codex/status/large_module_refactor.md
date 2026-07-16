# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Station-calendar contact-count callback ownership cleanup.

Status:
Complete and published.

Selected slice:
Replace station-calendar contact-count callbacks with direct primitive and
collection-aggregation support.

Why this slice:
Both callbacks map to existing support, with focused contact-intent/contention
tests covering nested station-calendar evidence.

Current coupling/problem:
The station-calendar contact-count validator receives equality checks and list
counting through a facade-assembled keyword bag.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Fixture/report/check order, derived status/counts, comparison errors,
  validation levels, and exact paths/messages.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/station_calendar_contact_count_contracts.ex`
- `lib/orbital_dynamics/schema/station_calendar_report_contracts.ex`

Definition of done:
Station-calendar contact-count callback plumbing is gone from both callers,
focused nested/export tests and fingerprint pass, and xref shows direct
primitive/collection dependencies.

Behavior/schema changes:
None. Contact identity, intervals, timeline/source-window matching, model limits,
reservation metadata, paths/messages, and schema output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors`
- `mix test test/orbital_dynamics/schema/communications_report_fixtures_test.exs:6 test/orbital_dynamics/schema/contact_allocation_contracts_test.exs:682 test/orbital_dynamics/schema_export_test.exs`
  (5 passed, 10 excluded)
- `mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- Contract fingerprint:
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`
- `mix xref callers OrbitalDynamics.Schema.StationCalendarContactCountContracts`
- `mix xref graph --source lib/orbital_dynamics/schema/station_calendar_contact_count_contracts.ex --format plain`
- `mix format --check-formatted`
- `git diff --check`

Verification gaps:
- Full suite not run.

Last commit:
`9e7d5d5a` (`Collapse station calendar count callbacks`).

Next candidate:
Audit the three small resource-projection flow-summary aggregators and their
parent callback boundary; keep mixed activity-context deferred.

Blocked:
No.

Notes:
- Starting point: `schema.ex` is 14,153 lines.
- Ending point: `schema.ex` is 14,145 lines; the contact-count validator is 24
  lines.
- A compile-first gate exposed and removed the same callback forwarding in
  `StationCalendarReportContracts` before tests ran.
- The generated schema export was byte-for-byte unchanged.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Station-calendar-precedence-summary callback ownership cleanup.

Status:
Complete and published.

Result:
- Removed the 16-function station-calendar-precedence facade bag and all
  callback arguments and application wrappers from
  `StationCalendarPrecedenceSummaryContracts`.
- The family now directly uses primitive, stable-ID, and collection-aggregation
  owners; station-calendar model limits stay explicit at the schema boundary.
- Preserved the public schema validation/report facade and checked-in artifact
  contract.
- Reduced `schema.ex` from 13,157 to 13,136 lines and station-calendar
  precedence contracts from 492 to 387 lines.
- Published implementation commit `1521a1bc`.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Station-calendar precedence contract, runtime generation, curated validation
  fixture, focused export-task, deterministic bundle, and checked-in export
  coverage: 6 passed, 230 excluded.
- Full schema export left `schemas/` unchanged; the SHA-256 over
  `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref, formatting, callback-residue checks, bounded diff review, and
  `git diff --check` passed.

Verification gaps:
- Full suite not run; focused command-window/export and handoff coverage was
  used for this behavior-preserving boundary cleanup.

Next candidate:
- Station-reservation-report callback ownership cleanup. Its sole schema caller
  feeds a 22-function bag into a 509-line module; the same direct validation
  owners are available and the report model list can stay explicit.

Blocked:
No.

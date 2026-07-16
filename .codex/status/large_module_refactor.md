# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Branch-event callback ownership cleanup.

Status:
Complete and published.

Result:
- Removed the shared 20-function callback bag and adapter wrappers from event,
  branch-summary, and trust-boundary count validation.
- The family now directly uses primitive, stable-ID, collection, and
  candidate-diff owners; the schema-local string-list-map behavior moved into
  the family unchanged.
- All three schema callers use the direct BranchEvent arities, including the
  count validator needed by station-calendar reports.
- Reduced `schema.ex` from 13,081 to 13,053 lines and BranchEvent contracts from
  708 to 628 lines.
- Published implementation commit `43670701`.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Parent-focused strategy-branch lint, branch-comparison count,
  communications-report trust-boundary, deterministic-bundle, and checked-in
  export coverage: 5 passed, 5 excluded.
- The read-only reviewer ran 26 focused lint, optimizer, timeline-report, and
  JSON-schema tests successfully and found no issues.
- Full schema export left `schemas/` unchanged; the SHA-256 over
  `{Schema.contracts(), Schema.json_schema_bundle()}` remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref, formatting, callback-residue checks, bounded diff review, and
  `git diff --check` passed.

Verification gaps:
- Full suite not run; focused branch-event/export coverage was used for this
  behavior-preserving boundary cleanup.

Next candidate:
- Station-calendar-report callback ownership cleanup. Its sole schema delegate
  feeds a 32-function bag into a 1,077-line module; BranchEvent count validation
  is now directly callable, and the remaining primitive, collection, stable-ID,
  aggregation, model, and error owners are available.

Blocked:
No.

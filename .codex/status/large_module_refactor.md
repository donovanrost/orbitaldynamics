# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
No slice selected.

Status:
Slice complete and pushed.

Selected boundary:
Completed the existing
`OrbitalDynamics.Schema.StationReservationValidation` extraction by moving the
default-path arity into the owner, routing contract clauses and callback tables
directly to it, and removing five facade pass-through clauses.
Preserved all `OrbitalDynamics.Schema` public facades and validation output.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,602 lines.
- Station calendar/reservation validation already has a focused owner, but the
  facade retains a default-path adapter plus four one-hop wrappers referenced
  by contract clauses and campaign/candidate callback tables.
- The selected code has one responsibility: route optional station-calendar
  reports and reservation review/hold/import-readiness summaries to the owner.
- Callback-table composition, other
  artifact-family validation, JSON Schema generation, and all public routing
  remain outside the boundary.
- Exact issue ordering, paths, messages, malformed-input behavior, callback
  wiring, public validation results, and schema exports must remain unchanged.

Implementation:
- Added the two-argument optional calendar-report entry point to
  `StationReservationValidation`, preserving the facade's established default
  path.
- Routed station calendar/reservation contract clauses plus campaign-plan,
  campaign-repair, and candidate-refresh callback tables directly to the owner.
- Removed five one-hop private wrapper clauses.
- `schema.ex` moved from 6,602 to 6,580 lines; the focused owner is 51 lines.

Verification:
- Pre-change strict focused baseline: 23 campaign/communications/station
  contract tests passed.
- Post-change strict focused verification: the same 23 tests passed; 18
  broader validation and station/campaign fixture tests also passed.
- Static checks found no migrated station-reservation wrappers or local
  callback captures remaining; xref reports `schema.ex` as the runtime caller
  of `StationReservationValidation`.
- No checked-in schema export changed.
- Forced warnings-as-errors compile passed across 4,050 files.
- Formatting and `git diff --check` passed; the worktree was clean after the
  implementation commit.

Behavior/schema changes:
None intended.

Last completed slice:
Schema station-reservation validation routing cleanup, selected in `d4db8b09`
and implemented in `bc5ce973`.
`schema.ex` moved from 6,602 to 6,580 lines by completing routing to the
existing StationReservationValidation owner.

Next candidate:
Re-rank the remaining schema wrapper clusters while preserving
dependency-injecting adapters.

Blocked:
No.

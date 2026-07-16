# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Station-calendar-provider callback-bag collapse.

Status:
Selected; implementation pending.

Selected slice:
Replace the 9-entry callback bag in `StationCalendarProviderContracts` with
direct primitive, stable-ID, and collection owners plus local error ownership.

Why this slice:
Live inventory leaves `schema.ex` at 11,627 lines. The 250-line provider owner
and its sole Schema caller route only shared validation operations and error
construction through lookup; no genuine Schema domain hook remains.

Public facade to preserve:
`OrbitalDynamics.Schema.validate_artifact/2`, station-calendar-provider and
entry validation behavior, trust/station/availability requirements, interval
and duplicate-ID messages/order, report consumers, and exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/station_calendar_provider_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- compile with warnings as errors
- focused station-calendar provider/report, schema, and operator-review tests
- broader candidate-refresh/operator-review regression
- schema export trio and checked-in export regeneration
- compile-connected xref, format, diff hygiene, and bounded review

Definition of done:
No station-calendar-provider callback bag or lookup trampolines remain; direct
shared owners and local error construction preserve validation; focused,
broader, and export checks pass; and bounded review finds no blocker.

Verification gaps:
- Full repository suite not run.
- Known baseline: full contact-filter file remains 87/88 due nil-message
  behavior in `SuppressedCandidateContracts`; unrelated to these slices.

Last completed slice:
Suppression-handoff callback-bag collapse published as `01b36c08`:
`schema.ex` fell from 11,641 to 11,627 lines and its owner from 293 to 273. The
6-entry bag became direct primitives/local errors and one evidence boundary.
125 focused, 1,167 broader, and 22 export tests passed; compile, xref, format,
diff hygiene, checked-in regeneration, and bounded review were clean.

Blocked:
No.

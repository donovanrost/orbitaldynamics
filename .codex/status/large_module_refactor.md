# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Completed: station-calendar/link-capacity handoff count ownership cleanup.

Status:
Completed and published.

Selected slice:
Move generic count/list equality into primitive support and let both handoff
contracts call it directly.

Why this slice:
Both one-entry callback bags route the same invariant; the existing link-capacity
report callback remains compatible through the facade import.

Current coupling/problem:
Resolved. Primitive support owns the generic invariant, both handoff contracts
call it directly, and the facade retains only its separately shared count
delegate.

Public facade preserved:
- `OrbitalDynamics.Schema.validate_artifact/2`
- `OrbitalDynamics.Schema.validation_report/2`
- Handoff row gating, count/list validation order, paths, and exact errors.

Files changed:
- `.codex/status/large_module_refactor.md`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/primitive_validation.ex`
- `lib/orbital_dynamics/schema/station_calendar_handoff_contracts.ex`
- `lib/orbital_dynamics/schema/link_capacity_handoff_contracts.ex`

Definition of done:
The generic helper is support-owned, both callback bags/dynamic wrappers are
gone, focused/broad tests and exact fingerprint pass, and xref is clean.

Behavior/schema changes:
None. Handoff gating, count/list order, paths, messages, and deterministic
schema output remain unchanged.

Tests run:
- `mix compile --warnings-as-errors` passed.
- 34 operator-review, Cadence-import, communications, JSON-schema, export, and
  exact link-capacity count-mismatch tests passed; 112 unrelated tests in the
  selected Cadence-import file were excluded by the line selector.
- Exact schema fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref shows the facade callers and each handoff contract's sole dependency on
  primitive support.
- Formatting, `git diff --check`, and checked-in schema cleanliness passed.

Verification gaps:
- Full suite not run; the focused handoff/export gate and deterministic
  fingerprint are the verification boundary for this slice.

Last commit:
`1c0fa889` (`Collapse handoff count callbacks`).

Next candidate:
Reassess another one-entry support callback; keep mixed activity-context
ownership deferred.

Blocked:
No.

Notes:
- `schema.ex` is 14,564 lines after this slice (down from 14,587).
- `list_count/2` remains on the facade because seven unrelated callback bags
  still consume that delegate; the failed pre-test compile exposed this edge,
  it was restored, and all verification was rerun.
- Activity-context cleanup was audited and deferred because its 17 callbacks
  include facade-owned validators; this slice is the bounded alternative.
- Parent review/publishing is the active-mode fallback because subagent
  delegation is unavailable.

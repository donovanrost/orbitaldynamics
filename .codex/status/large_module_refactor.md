# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactFilter station-state resolution extraction.

Status:
Completed and pushed in `bc495074`.

Selected boundary:
Extract station overlap matching, direction/window filtering, severity and
ambiguity selection, capacity/availability evaluation, reservation/trust
context aggregation, and numeric evidence normalization into
`OrbitalDynamics.Communications.ContactFilter.StationState`.
Preserve all ContactFilter and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `communications/contact_filter.ex` at 1,898 lines, the
  largest ordinary eligible facade.
- ContactFilter delegates contact normalization and provider-counteroffer
  context, while station-state resolution remains inline at lines 608-1,132.
- The selected block has one responsibility: resolve the applicable declared
  station state and its availability, capacity, reservation, trust, and
  ambiguity evidence for a contact window.
- Public filtering/report construction, invalid-input classification,
  suppressed-row projection, provider-contention handoff, approval policy, and
  all public contracts remain outside the boundary.
- Exact direction/window matching, severity/tie precedence, ambiguity IDs,
  capacity selection, reservation/trust aggregation, numeric normalization,
  omission behavior, public facade output, and error behavior must remain
  unchanged.

Implementation:
- Added `OrbitalDynamics.Communications.ContactFilter.StationState` as the owner
  of overlap matching, direction/window filtering, severity and ambiguity
  selection, availability/capacity evaluation, reservation/trust context, and
  numeric evidence normalization.
- Preserved ContactFilter and root public APIs; the facade retains narrow
  delegates for suppression decisions and suppressed-row projection.
- Removed the station-state resolver helper family from the facade while
  leaving invalid-input handling, row projection, provider context, and
  approval policy in their existing owners.
- `contact_filter.ex` moved from 1,898 to 1,365 lines; the new owner is 633
  lines.

Verification:
- Strict focused baseline passed all 42 ContactFilter tests.
- Exact old/new public parity passed for four deterministic filter results:
  matched/unmatched reservations with ambiguous maintenance and direction
  filtering, direct zero-capacity evidence, provider-counteroffer review, and
  empty input.
- Post-extraction focused and adjacent schema verification passed all 50 tests.
- Static checks confirm the station-state implementation helpers left the
  facade; xref reports only ContactFilter as a runtime caller.
- Strict warning-clean forced compile passed for 4,003 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
ContactFilter station-state resolution extraction, selected in `3d523698` and
implemented in `bc495074`.
`contact_filter.ex` moved from 1,898 to 1,365 lines; the dedicated StationState
owner is 633 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `recommendation_risk_context.ex` is now the largest ordinary
eligible facade at 1,893 lines, followed by OrbitData and StationCalendar.

Blocked:
No.

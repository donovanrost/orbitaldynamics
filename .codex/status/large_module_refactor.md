# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback station-capacity contract consolidation.

Status:
Completed and pushed in `99d57227`.

Selected boundary:
Move the station-capacity fraction/percent path contracts and unit-tagged
capability metadata into the existing
`OrbitalDynamics.TimelineFeedback.StationCalendarContext` owner that already
uses the value paths for parsing and aggregation. Preserve all TimelineFeedback
and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `timeline_feedback.ex` at 1,993 lines, the largest
  ordinary eligible facade.
- TimelineFeedback already delegates to twenty-seven focused owners, including
  StationCalendarContext for capacity evidence and reservation context.
- The facade still duplicates station fraction, percent, and combined value
  path contracts at lines 39-78 solely for capabilities, while the owner has
  the parsing value-path contract at lines 12-30.
- Reconciliation, matching, realized normalization, operational feedback,
  identities, outcomes, success factors, resources, timing, and all other
  capability contracts remain outside the boundary.
- Exact fraction/percent/value path ordering, unit metadata shape, source-path
  aliases, station-capacity aggregation, public capability output, and all
  reconciliation behavior must remain unchanged.

Implementation:
- Added station-capacity fraction/percent contracts and the unit-tagged value
  path projection to the existing StationCalendarContext owner.
- Preserved TimelineFeedback capability and reconciliation APIs as delegates.
- Removed all station-capacity path attributes and the metadata projection
  helper from the facade.
- `timeline_feedback.ex` moved from 1,993 to 1,948 lines; the existing owner
  moved from 241 to 269 lines.

Verification:
- Strict focused baseline passed all 73 TimelineFeedback tests.
- Exact old/new public parity passed for three deterministic captures: the six
  capability contracts, direct station-capacity evidence reconciliation, and
  source station-calendar capacity reconciliation.
- Post-consolidation focused and adjacent verification passed all 76 tests.
- Static checks confirm only StationCalendarContext declares the three path
  contracts; xref reports only TimelineFeedback as a runtime caller.
- Strict warning-clean forced compile passed for 3,994 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
TimelineFeedback station-capacity contract consolidation, selected in
`efa062e9` and implemented in `99d57227`.
`timeline_feedback.ex` moved from 1,993 to 1,948 lines; the existing
StationCalendarContext owner moved from 241 to 269 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `resource_projection.ex` is now the largest ordinary eligible
facade at 1,981 lines, followed by ContactContention and ResourceFilter.

Blocked:
No.

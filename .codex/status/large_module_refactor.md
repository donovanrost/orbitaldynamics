# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback station-capacity contract consolidation.

Status:
Selected; strict focused baseline pending.

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
Pending.

Verification:
Pending strict focused baseline, exact old/new public parity, focused and
adjacent tests, static ownership checks, xref, strict warning-clean compile,
formatting, and diff checks.

Behavior/schema changes:
None intended.

Last completed slice:
OrbitData OMM metadata extraction, selected in `16cee79c` and implemented in
`20216348`.
`orbit_data.ex` moved from 2,016 to 1,856 lines; the dedicated OMM metadata
owner is 286 lines.

Next candidate:
Complete the selected TimelineFeedback station-capacity contract
consolidation.

Blocked:
No.

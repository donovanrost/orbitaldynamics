# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar precedence-summary extraction.

Status:
Completed and pushed in `b0d0e175`.

Selected boundary:
Extract row-derived station-calendar availability precedence aggregation,
higher-precedence reservation surfacing, contact/reservation routing maps, and
precedence-specific list/count helpers into
`OrbitalDynamics.Communications.StationCalendar.PrecedenceSummary`. Preserve
all StationCalendar and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `communications/station_calendar.ex` at 2,068 lines,
  the largest ordinary eligible facade.
- StationCalendar already delegates to twelve responsibility-focused owners;
  its precedence-summary builder remains in the facade at lines 801-876 with a
  cohesive set of precedence-specific routing helpers near lines 1,823-1,914.
- The new owner will receive facade-owned schema/model-limit values explicitly,
  avoiding ownership changes to public dispatch or capability contracts.
- Contact overlay, station matching, provider contention/counteroffers,
  reservation reports and hold readiness, approval policy, capacity handling,
  feedback validation, and shared facade aggregators remain outside the
  boundary.
- Exact string/atom input parity, source/default selection, sparse output,
  deterministic sorting, counts, applied/overlap routing, higher-precedence
  reservation routing, and pass-through summary behavior must remain unchanged.

Implementation:
- Added `OrbitalDynamics.Communications.StationCalendar.PrecedenceSummary` as
  the owner of row-derived availability/status counts, overlap routing,
  higher-precedence reservation surfacing, and deterministic contact/
  reservation routing maps.
- Preserved all StationCalendar and root public APIs; the facade passes its
  existing summary contract, source artifact contract, and model limits to the
  new owner.
- Removed the precedence builder and precedence-only helper family from the
  facade while retaining shared report aggregators used by other paths.
- `communications/station_calendar.ex` moved from 2,068 to 1,911 lines; the new
  owner is 218 lines.

Verification:
- Strict focused baseline passed all 42 StationCalendar tests.
- Exact old/new public parity passed for five captured cases: complex routing
  and counts, atom-key/value normalization, empty reports, and string- and
  atom-keyed pass-through summaries.
- Focused and communications-contract verification passed 50 tests.
- Static checks confirm the old builder and precedence-only helpers left the
  facade; xref reports only StationCalendar as a runtime caller of the owner.
- Strict warning-clean forced compile passed for 3,988 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
StationCalendar precedence-summary extraction, selected in `2bfb28f3` and
implemented in `b0d0e175`.
`communications/station_calendar.ex` moved from 2,068 to 1,911 lines; the
dedicated precedence-summary owner is 218 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `communications/contact_filter.ex` and `resource_filter.ex` are
now the largest ordinary eligible facades near 2,060 lines.

Blocked:
No.

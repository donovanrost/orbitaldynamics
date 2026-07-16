# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh station-calendar context extraction.

Status:
Complete; ready to publish.

Result:
- Extracted stable-ID lists, count/direction maps, direction routes, capacity
  fractions, and provider contention into the new 191-line
  `CandidateRefreshStationCalendarContracts` owner.
- Preserved `CandidateRefreshReportContracts.validate_station_calendar_context/4`
  as a thin public facade with its callback-list guard unchanged.
- Removed all stale station-calendar helpers and imports from the multi-family
  parent, reducing it from 1,464 to 1,297 lines.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Focused station-calendar replay/provider/wrapper/provenance/schema coverage
  passed 27/27.
- The full `test/orbital_dynamics/candidate_refresh` directory passed 755/755.
- Schema export coverage passed 22/22.
- Full export left `schemas/` unchanged; the bundle fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Parent/new-module compile-connected xref, formatting, new-file whitespace,
  and `git diff --check` passed.
- The read-only reviewer found no issues, independently passed compile and 14
  focused tests, and verified ordering, paths/messages, routing edge cases,
  provider contention, public signatures, imports, and dependency shape.

Verification gaps:
- Full repository suite not run.

Last commit:
Pending publication; prior handoff `7872d52a`.

Next candidate:
- Inspect the remaining candidate-refresh report context clusters and select one
  cohesive owner extraction behind an existing public facade.

Blocked:
No.

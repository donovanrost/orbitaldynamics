# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar affected-contact projection extraction.

Status:
Completed and pushed in `42b4bc3f`.

Selected boundary:
Extract affected-contact row identity/evidence projection, operator
action/reason selection, and deterministic duplicate-row disambiguation into
`OrbitalDynamics.Communications.StationCalendar.AffectedContact`.
Preserve all StationCalendar and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `communications/station_calendar.ex` at 1,670 lines,
  the
  largest ordinary eligible facade.
- StationCalendar already delegates fifteen focused responsibilities, while
  affected-contact projection and collision handling remain inline at lines
  1,261-1,459.
- The selected block has one responsibility: project annotated contact/calendar
  evidence into stable report rows and disambiguate colliding row identities.
- Contact matching/annotation, provider contention, approval policy,
  reservation/counteroffer summaries, and all public contracts remain outside
  the boundary.
- Exact IDs, overlap evidence, feedback normalization, counteroffer deltas,
  reservation/trust context, action/reason precedence, omission behavior,
  collision suffixes/counts, ordering, public output, and error behavior must
  remain unchanged.

Implementation:
- Added `OrbitalDynamics.Communications.StationCalendar.AffectedContact` as the
  owner of affected-contact row identity/evidence, overlap and feedback
  normalization, operator action/reason selection, and deterministic duplicate
  row disambiguation.
- Wired overlay report construction directly to the owner while preserving
  StationCalendar and root public APIs.
- Kept contact matching/annotation, provider contention, approval policy, and
  reservation/counteroffer summaries outside the boundary.
- `station_calendar.ex` moved from 1,670 to 1,391 lines; the new owner is 302
  lines.

Verification:
- Strict focused baseline passed all 42 StationCalendar tests.
- Exact old/new public parity passed for four deterministic overlay results:
  rich reservation/counteroffer evidence, duplicate affected-row identities,
  invalid feedback evidence, and empty input.
- Post-extraction focused and adjacent StationCalendar, operator-review, repair
  annotation, and replay-summary verification passed all 57 tests.
- Static checks confirm affected-contact projection, action/reason, overlap,
  feedback, and collision helpers left the facade; xref reports only
  StationCalendar as a runtime caller.
- Strict warning-clean forced compile passed for 4,015 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
StationCalendar affected-contact projection extraction, selected in `a006e1c8`
and implemented in `42b4bc3f`.
`communications/station_calendar.ex` moved from 1,670 to 1,391 lines; the
dedicated AffectedContact owner is 302 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `communications/contact_contention.ex` is now the largest ordinary
eligible facade at 1,665 lines, followed by RecommendationRiskContext and
OperationalReadiness.

Blocked:
No.

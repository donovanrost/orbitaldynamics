# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
StationCalendar affected-contact projection extraction.

Status:
Selected; strict focused baseline pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
OperationalReadiness execution-boundary summary extraction, selected in
`59df6806` and implemented in `35b2cebf`.
`operational_readiness.ex` moved from 1,686 to 1,635 lines; the dedicated
ExecutionBoundarySummary owner is 63 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `communications/station_calendar.ex` is now the largest ordinary
eligible facade at 1,670 lines, followed by ContactContention and
RecommendationRiskContext.

Blocked:
No.

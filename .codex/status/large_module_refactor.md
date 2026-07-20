# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactContention resolution-summary projection extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract the compact resolution-summary artifact projection into
`OrbitalDynamics.Communications.ContactContention.ResolutionSummary`.
Preserve all ContactContention and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `communications/contact_contention.ex` at 1,665 lines,
  the largest ordinary eligible facade.
- ContactContention already delegates eight focused responsibilities, while the
  resolution-summary artifact projection remains inline at lines 406-523.
- The selected block has one responsibility: derive compact routing counts,
  identity sets, grouped identities, and capacity-pack demand fields from a
  resolution report.
- Contention detection, contact annotation, resolution recommendation policy,
  approval requirements, capabilities, and all public contracts remain outside
  the boundary.
- Exact schema/model fields, counts, identity omission and sorting, grouped
  routing maps, capacity-demand fields, assumptions, idempotent inputs, public
  output, and error behavior must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
StationCalendar affected-contact projection extraction, selected in `a006e1c8`
and implemented in `42b4bc3f`.
`communications/station_calendar.ex` moved from 1,670 to 1,391 lines; the
dedicated AffectedContact owner is 302 lines.

Next candidate:
After this slice, re-rank the live checkout. RecommendationRiskContext and
OperationalReadiness are the next largest ordinary eligible facades.

Blocked:
No.

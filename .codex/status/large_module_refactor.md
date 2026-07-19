# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactContention station-calendar context extraction.

Status:
Completed and pushed in `935abd1b`.

Selected boundary:
Extract station availability precedence, capacity fraction/percent contracts,
capability metadata, capacity aggregation, reservation/provider context
aggregation, and the station-calendar context field contract into
`OrbitalDynamics.Communications.ContactContention.StationCalendarContext`.
Preserve all ContactContention and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `communications/contact_contention.ex` at 1,978 lines,
  the largest ordinary eligible facade.
- ContactContention already delegates to seven focused owners, while the
  station-calendar context builder and helper family still occupy lines
  1,012-1,275 and its availability/capacity contracts remain at lines 19-66.
- The selected block has one responsibility: aggregate normalized station
  availability, capacity, provider, reservation, direction, trust-boundary,
  and expiration evidence for contention groups and recommendations.
- Group detection, timing, feedback, contact identity/normalization, capacity
  demand, priority policy, resolution summaries, approval policy, and all
  other capability contracts remain outside the boundary.
- Exact path ordering, unit metadata, availability severity/aliases, fraction
  min/max behavior, list normalization, field names, group/recommendation
  reports, summaries, and error behavior must remain unchanged.

Implementation:
- Added
  `OrbitalDynamics.Communications.ContactContention.StationCalendarContext` as
  the owner of station availability/capacity contracts, normalized context
  aggregation, and the context field list.
- Preserved ContactContention and root public APIs as capability, report,
  annotation, and resolution delegates.
- Routed contact normalization's unavailable-status aliases through the same
  owner because normalization consumes that station-calendar contract.
- `communications/contact_contention.ex` moved from 1,978 to 1,665 lines; the
  new owner is 333 lines.

Verification:
- Strict focused baseline passed all 40 ContactContention tests.
- Exact old/new public parity passed for four deterministic captures:
  station-calendar capability contracts, annotated contacts, contention
  report, and resolution report with mixed availability/capacity,
  provider/reservation, direction, trust-boundary, and expiration evidence.
- Post-extraction focused and adjacent verification passed all 50 tests.
- Static checks confirm the new owner solely declares the availability and
  station-capacity contracts and owns the context helper family; xref reports
  only ContactContention as a runtime caller.
- Strict warning-clean forced compile passed for 3,996 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
ContactContention station-calendar context extraction, selected in `5e23d9f3`
and implemented in `935abd1b`.
`communications/contact_contention.ex` moved from 1,978 to 1,665 lines; the
dedicated StationCalendarContext owner is 333 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `resource_filter.ex` is now the largest ordinary eligible facade at
1,964 lines, followed by ContactAllocation and TimelineFeedback.

Blocked:
No.

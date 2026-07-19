# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactAllocation specialized-summary ownership extraction.

Status:
Completed and pushed.

Selected boundary:
Move the station-pressure, capacity-pack, reservation-conflict, and provider
reservation-request summary builders into the existing
`OrbitalDynamics.Communications.ContactAllocation.AllocationSummary` owner.
Remove the facade's duplicate summary aggregation helpers while preserving all
existing `ContactAllocation` public summary clauses as compatibility delegates.

Selection evidence:
- Live re-ranking places `communications/contact_allocation.ex` at 3,071 lines,
  fourth behind Schema, Timeline, and MissionPlan.Activity and ahead of
  TimelineFeedback, ContactContention, LinkCapacity, ResourceProjection,
  Manifest, StationCalendar, OrbitalDynamics, RecommendationRiskContext, and
  OperationalReadiness.
- The four private builders and their aggregation helpers form one closed
  summary responsibility from lines 1,149-1,843. Their normalization, status,
  ID grouping, capacity-total, station-pressure, reservation-expiration, and
  deterministic ordering helpers already exist in the extracted
  `AllocationSummary` owner because the general summary uses the same rules.
- The facade's public input-shape clauses, report construction, allocation
  pipeline, capabilities, contact validation, resource/status filtering,
  capacity packing, provider counteroffer handling, and returned-contact
  assembly remain outside this boundary.
- Existing schema contracts, option handling (including reservation-conflict
  `:now_s`), capability assumptions, model limits, row selection, identifier
  grouping, ordering, numeric normalization, and artifact-only execution
  boundary must remain unchanged.

Verification:
- Focused baseline before implementation:
  `test/orbital_dynamics/communications/contact_allocation_test.exs` passed
  70 tests.
- Strict compilation after implementation:
  `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force --warnings-as-errors`
  compiled 3,943 files successfully.
- Focused regression:
  `test/orbital_dynamics/communications/contact_allocation_test.exs` passed
  70 tests.
- Adjacent contract/operator/handoff regressions passed 33 tests across
  `operator_review/contact_allocation_test.exs`, both contact-allocation schema
  contract files, the validation fixture, the specialized CandidateRefresh
  handoff, and campaign-planner pressure strategy.
- The broader ContactAllocation CandidateRefresh replay bundle plus all three
  focused campaign-planner ContactAllocation consumers passed 67 tests.
- Exact old/new comparison against selection commit `e8ce52b8` compiled the
  selected facade under a comparison module name and matched eight outputs
  exactly: a live allocation result, general summaries with default and
  explicit `:now_s`, station-pressure, capacity-pack, reservation-conflict
  with declared and expired timing, and provider-reservation-request.
- `git diff --check` passed.
- `mix xref callers
  OrbitalDynamics.Communications.ContactAllocation.AllocationSummary` reports
  only the ContactAllocation facade as a runtime caller; compile-connected
  xref reports no unexpected coupling.
- Static review confirmed the owner now exposes the general builder,
  report-derived summary fields, and the four specialized builders; public
  input-shape clauses, allocation orchestration, contact validation,
  filtering, packing, provider counteroffers, and returned-contact assembly
  remain in or behind the facade.

Behavior/schema changes:
None. Existing public clauses, report and summary contracts, option handling,
row selection, aggregation, normalization, ordering, model limits, capability
assumptions, and artifact-only execution boundaries are preserved.

Last completed slice:
ContactAllocation specialized-summary ownership extraction, selected in
`e8ce52b8` and implemented in `94d0835e`.
`communications/contact_allocation.ex` moved from 3,071 to 2,197 lines; the
existing summary owner moved from 710 to 1,246 lines while eliminating the
facade's duplicate aggregation machinery.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.

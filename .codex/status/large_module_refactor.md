# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
LinkCapacity contact-normalization extraction.

Status:
Completed and pushed.

Selected boundary:
Extract recursive key/string conversion, numeric parsing, contact shape,
station identity, timing fields, station-calendar status/direction trees,
activity type aliases, nested throughput-model normalization, and compact-map
behavior into
`OrbitalDynamics.Communications.LinkCapacity.ContactNormalization`.
Preserve narrow private facade delegates and the existing public API.

Selection evidence:
- Live re-ranking places `communications/link_capacity.ex` at 3,016 lines,
  fourth behind Schema, Timeline, and MissionPlan.Activity and ahead of
  ResourceProjection, Manifest, StationCalendar, OrbitalDynamics,
  RecommendationRiskContext, OperationalReadiness, TimelineFeedback,
  ContactContention, and ContactAllocation.
- The selected terminal family occupies lines 2,780-3,015 and is the single
  normalization path used before link-capacity validation, grouping,
  throughput, and summary assembly.
- Numeric parsing is also used by throughput, completion, policy, and summary
  helpers, so the new owner exposes it through the existing facade helper;
  recursive status/direction and throughput-model helpers remain private to
  the owner.
- Report/summary aggregation, station-capacity evidence, contact feedback and
  identity, relay paths, input validation, throughput/completion derivation,
  downlink policy, approval policy, station availability, contracts, and
  public clauses remain outside this boundary.
- Existing recursive key conversion, atom/boolean handling, numeric-string
  parsing, station identity precedence, canonical time precedence, unavailable
  aliases, status/direction normalization, direction-list cleanup, nested
  station-calendar recursion, type inference, throughput-model shape handling,
  nil omission, and deterministic output must remain unchanged.

Verification:
- Focused baseline before implementation:
  `test/orbital_dynamics/communications/link_capacity_test.exs` passed 44
  tests.
- Strict compilation after implementation:
  `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force --warnings-as-errors`
  compiled 3,946 files successfully.
- Focused regression:
  `test/orbital_dynamics/communications/link_capacity_test.exs` passed 44
  tests.
- All adjacent Cadence-import, campaign-planner, CandidateRefresh replay,
  operator-review, and validation-fixture LinkCapacity consumers passed 44
  tests.
- Exact old/new comparison against selection commit `7f8dedfb` compiled the
  selected facade under a comparison module name and matched five outputs
  exactly: a rich report, compact summary, summary from source inputs, report
  handoff, and summary handoff.
- The exact inputs covered atom/string keys, nested station identity,
  canonical and alternate times, numeric strings, unavailable aliases,
  status/direction lists, recursive station-calendar sources, type/direction
  aliases, nested throughput-model keys, selected matching, policy values, and
  invalid candidate/selected shapes.
- `git diff --check` passed.
- `mix xref callers
  OrbitalDynamics.Communications.LinkCapacity.ContactNormalization` reports
  only the LinkCapacity facade as a runtime caller; compile-connected xref
  reports no unexpected coupling.
- Static review confirmed the facade preserves seven narrow delegates while
  report/summary aggregation, station capacity, feedback/identity, relay
  paths, validation, throughput/completion, downlink and approval policy,
  station availability, contracts, and public clauses remain outside the
  boundary.

Behavior/schema changes:
None. Existing key/numeric normalization, status and direction aliases,
recursive source handling, throughput-model normalization, report contracts,
and deterministic output are preserved.

Last completed slice:
LinkCapacity contact-normalization extraction, selected in `7f8dedfb` and
implemented in `053ed894`.
`communications/link_capacity.ex` moved from 3,016 to 2,792 lines; the
dedicated contact-normalization owner is 307 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.

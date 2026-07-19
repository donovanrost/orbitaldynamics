# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactContention contact-normalization extraction.

Status:
Completed and pushed.

Selected boundary:
Extract recursive key/string conversion, numeric parsing, contact shape,
station identity, timing/numeric fields, station-calendar status trees,
activity type/direction aliases, compact-map behavior, and deterministic value
encoding into
`OrbitalDynamics.Communications.ContactContention.ContactNormalization`.
Preserve narrow private facade delegates and the existing public API.

Selection evidence:
- Live re-ranking places `communications/contact_contention.ex` at 3,035
  lines,
  fourth behind Schema, Timeline, and MissionPlan.Activity and ahead of
  LinkCapacity, ResourceProjection, Manifest, StationCalendar,
  OrbitalDynamics, RecommendationRiskContext, OperationalReadiness,
  TimelineFeedback, and ContactAllocation.
- The selected terminal family occupies the facade's final normalization block
  from numeric parsing through contact normalization, with recursive status
  normalization and value encoding used consistently by annotation, report,
  resolution, policy, evidence, and sorting paths.
- The owner can expose eight narrow functions while receiving the three
  policy catalogs that differ by caller: unavailable aliases, default priority
  fields, and provider direction aliases. Existing facade call sites remain
  unchanged behind private delegates.
- Contention grouping, timing metrics, resolution summaries, capacity and
  station evidence, feedback aggregation, approval policy, resolution policy,
  identity validation, throughput derivation, report contracts, and public
  clauses remain outside this boundary.
- Existing recursive key conversion, atom/boolean handling, numeric-string
  parsing, station identity precedence, canonical time precedence, status
  aliasing, nested station-calendar recursion, numeric priority normalization,
  type/direction inference, float encoding, nil omission, and deterministic
  output must remain unchanged.

Verification:
- Focused baseline before implementation:
  `test/orbital_dynamics/communications/contact_contention_test.exs` passed
  40 tests.
- Strict compilation after implementation:
  `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force --warnings-as-errors`
  compiled 3,945 files successfully.
- Focused regression:
  `test/orbital_dynamics/communications/contact_contention_test.exs` passed
  40 tests.
- All campaign-planner, CandidateRefresh replay, operator-review, and
  validation-fixture ContactContention consumers passed 55 tests.
- Exact old/new comparison against selection commit `16aa47c2` compiled the
  selected facade under a comparison module name and matched five end-to-end
  outputs exactly: annotation, report, resolution report, resolution summary,
  and resolution summary from source inputs.
- The exact inputs covered atom/string keys, nested station identity,
  canonical and alternate times, numeric priority strings, status aliases and
  lists, recursive station-calendar sources, type/direction aliases, provider
  throughput fields, policy normalization, and an invalid contact shape.
- `git diff --check` passed.
- `mix xref callers
  OrbitalDynamics.Communications.ContactContention.ContactNormalization`
  reports only the ContactContention facade as a runtime caller;
  compile-connected xref reports no unexpected coupling.
- Static review confirmed the facade preserves its existing helper call sites
  through six narrow delegates; grouping, resolution summaries,
  capacity/station evidence, feedback, approval/resolution policy, identity,
  throughput, contracts, and public clauses remain outside the boundary.

Behavior/schema changes:
None. Existing contact normalization, numeric parsing, status and direction
aliases, recursive source handling, float encoding, report contracts, and
deterministic output are preserved.

Last completed slice:
ContactContention contact-normalization extraction, selected in `16aa47c2`
and implemented in `8206862c`.
`communications/contact_contention.ex` moved from 3,035 to 2,805 lines; the
dedicated contact-normalization owner is 275 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.

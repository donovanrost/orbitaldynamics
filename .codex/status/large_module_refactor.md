# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback operational-context extraction.

Status:
Completed and pushed.

Selected boundary:
Extract resource, pointing, attitude, command-authority, lighting, and
observation-quality evidence maps into
`OrbitalDynamics.TimelineFeedback.OperationalContext`. Replace each six-map
merge sequence with one facade delegate while preserving merge order and the
existing TimelineFeedback public API.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 3,061 lines,
  fourth behind Schema, Timeline, and MissionPlan.Activity and ahead of
  ContactContention, LinkCapacity, ResourceProjection, Manifest,
  StationCalendar, OrbitalDynamics, RecommendationRiskContext,
  OperationalReadiness, and ContactAllocation.
- The selected evidence maps are always merged as one ordered sequence at four
  planned/realized row and activity-context call sites. Their builders occupy
  one contiguous family from lines 1,528-1,726, with resource-only scalar/list
  helpers immediately following the existing specialized context delegates.
- Realized lock/execution parsing and other facade consumers still use the
  general string/boolean helpers, so those shared facade helpers remain; the
  new owner receives stable-identity policy and directly reuses the existing
  ArtifactValue, RealizedIdentity, SuccessFactor, and Throughput owners.
- Reconciliation matching, activity identity, row assembly, product/provider
  context, link/station-calendar/thermal context, execution uncertainty,
  feedback aggregation, report contracts, and public clauses remain outside
  this boundary.
- Existing field precedence, nested-metadata fallback, stable identifier
  filtering, boolean/string/numeric parsing, unit-interval validation, nil
  omission, list normalization, merge order, and deterministic output must
  remain unchanged.

Verification:
- Focused baseline before implementation:
  `test/orbital_dynamics/timeline_feedback_test.exs` passed 73 tests.
- Strict compilation after implementation:
  `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force --warnings-as-errors`
  compiled 3,944 files successfully.
- Focused regression:
  `test/orbital_dynamics/timeline_feedback_test.exs` passed 73 tests.
- All eight adjacent TimelineFeedback consumers passed 26 tests across schema
  export, campaign strategy, CandidateRefresh build/replay, and operator-review
  suites.
- Exact old/new comparison against selection commit `933df86b` compiled the
  selected facade under a comparison module name and matched six rich outputs
  exactly: direct and metadata-fallback realized normalization, batch
  normalization, matched reconciliation, planned-only reconciliation, and
  activity state.
- The exact activities exercised all six evidence families, direct and alias
  fields, nested metadata fallback, numeric strings, booleans, stable
  identifiers, scalar/list normalization, unit-interval values, and
  planned/realized merge paths.
- `git diff --check` passed.
- `mix xref callers OrbitalDynamics.TimelineFeedback.OperationalContext`
  reports only the TimelineFeedback facade as a runtime caller;
  compile-connected xref reports no unexpected coupling.
- Static review confirmed the owner exposes only `build/2`; reconciliation,
  identity, row assembly, products/providers, link/station-calendar/thermal
  context, uncertainty, aggregation, report contracts, and public clauses
  remain outside the boundary.

Behavior/schema changes:
None. Existing operational-context precedence, parsing, stable-identity
filtering, nil omission, list ordering, merge order, report contracts, and
deterministic output are preserved.

Last completed slice:
TimelineFeedback operational-context extraction, selected in `933df86b` and
implemented in `88f7271c`.
`timeline_feedback.ex` moved from 3,061 to 2,809 lines; the dedicated
operational-context owner is 295 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.

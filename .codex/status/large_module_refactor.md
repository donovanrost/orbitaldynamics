# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback operational-context extraction.

Status:
Selected; implementation not started.

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
Pending implementation.

Behavior/schema changes:
None intended.

Last completed slice:
ContactAllocation specialized-summary ownership extraction, selected in
`e8ce52b8` and implemented in `94d0835e`.
`communications/contact_allocation.ex` moved from 3,071 to 2,197 lines; the
existing summary owner moved from 710 to 1,246 lines while eliminating the
facade's duplicate aggregation machinery.

Next candidate:
Implement and verify the selected TimelineFeedback operational-context
extraction.

Blocked:
No.

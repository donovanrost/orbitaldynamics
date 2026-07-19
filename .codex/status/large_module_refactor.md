# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Manifest ground-track crossing input extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract ground-track crossing request validation, rotation options,
constant/tabular Earth-orientation provider selection, and tabular sample
normalization into
`OrbitalDynamics.Study.Manifest.GroundTrackCrossingInput`.
Preserve the existing Manifest public API facade.

Selection evidence:
- Live re-ranking places `manifest.ex` at 3,836 lines, fourth behind Schema,
  Timeline, and MissionPlan.Activity and ahead of ResourceProjection,
  StationCalendar, ContactAllocation, and TimelineFeedback.
- The selected helper family owns one manifest-input responsibility spanning
  crossing shape, rotation configuration, provider selection, and provider
  sample normalization.
- The dedicated input owner can reuse the existing Manifest.InputField owner
  and public environment provider modules without duplicating parsing policy.
- Target parsing, candidate refresh, accepted planning state, run options,
  schema export, file loading, and study execution remain outside this
  boundary.
- Existing public APIs, error tuples, normalized keyword values, provider
  selection, ordering, and exported schema remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
StationCalendar provider-counteroffer report projection extraction, selected
in `4aadbd79` and implemented in `e0e40d24`.
`station_calendar.ex` moved from 3,924 to 3,804 lines; the dedicated report
owner is 217 lines.

Next candidate:
Implement and verify the selected Manifest ground-track crossing input
extraction.

Blocked:
No.

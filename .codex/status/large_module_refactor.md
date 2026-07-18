# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner station-pressure derivation orchestration extraction.

Status:
Ready for implementation.

Selected slice:
Move the private prior/mission station-calendar and mission reservation
review/hold pressure orchestration from `CampaignPlanner` into a new internal
`CampaignPlanner.DerivedStationPressureBranches` module with one ordered
`build/2` entry point.

Why this slice:
After the operational-review extraction, `CampaignPlanner` remains the largest
named implementation hotspot at 2,064 lines and 148 private functions. The
selected four-stage block is contiguous station report orchestration behind
dedicated station owners.

Current coupling/problem:
The public planner facade still selects station calendar/reservation reports
and owns provider-contention source-path callbacks despite the station pressure
family already owning branch construction.

Public facade to preserve:
`CampaignPlanner.strategy/1`, `strategy!/1`, file-backed entry points, branch
IDs/events/metadata, branch ordering and deduplication, scoring artifacts,
deterministic output, and all error behavior.

Likely files:
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/derived_station_pressure_branches.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The planner’s derived-branch pipeline delegates the exact existing four-stage
sequence to `DerivedStationPressureBranches.build/2`; the private wrapper
cluster is removed from the facade; public artifacts and ordering are
unchanged; focused station tests pass to their live baseline; strict
compile and independent review are clean.

Verification gaps:
- Focused station baseline is pending.
- The full planner directory retains five known baseline failures; none is in
  the selected focused files.

Tests run:
- Live inventory: `CampaignPlanner` is 2,064 lines with 148 private functions.
- Target cluster is 4 ordered pipeline calls and 4 private helpers.

Behavior/schema changes:
None.

Outcome:
No station-pressure extraction has started.

Last completed slice:
Operational-review derivation orchestration extraction published as
`a5ae4f60`: `CampaignPlanner` shrank from 2,113 to 2,064 lines; focused,
file-backed, and compile proof passed; independent review was clean. Handoff
published as `11756b23`.

Next candidate:
Publish this selection note, run the focused station baseline, then perform the
mechanical ordered extraction.

Blocked:
No.

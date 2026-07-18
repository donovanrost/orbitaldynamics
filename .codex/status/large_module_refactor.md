# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner timeline-pressure derivation orchestration extraction.

Status:
Ready for implementation.

Selected slice:
Move the private prior-plan/mission-state timeline-pressure source orchestration
from `CampaignPlanner` into a new internal
`CampaignPlanner.DerivedTimelinePressureBranches` module with one ordered
`build/3` entry point.

Why this slice:
After the prior extraction, live inventory shows `CampaignPlanner` remains the
largest named implementation hotspot at 2,875 lines. Its roughly 280-line
timeline cluster is cohesive report-to-branch orchestration behind existing
`TimelineSourceReports`, `TimelinePressureBranches`, and
`TimelineDiffPressureEvents` owners.

Current coupling/problem:
The public planner facade owns paired prior-plan and mission-state wrappers for
timeline diff, integrity, dependency impact, publication, lifecycle,
activity-lifecycle, precondition, and preservation pressure. This obscures the
strategy flow and spreads one ordered responsibility across many private
helpers.

Public facade to preserve:
`CampaignPlanner.strategy/1`, `strategy!/1`, file-backed entry points, branch
IDs/events/metadata, branch ordering and deduplication, scoring artifacts,
deterministic output, and all error behavior.

Likely files:
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/derived_timeline_pressure_branches.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The planner’s derived-branch pipeline delegates the exact existing timeline
sequence to `DerivedTimelinePressureBranches.build/3`; the private timeline
wrapper/source-row cluster is removed from the facade; public artifacts and
ordering are unchanged; focused timeline tests pass to their live baseline;
strict compile and independent review are clean.

Verification gaps:
- Baseline focused timeline test state is pending.
- The full planner directory has five known baseline failures recorded by the
  preceding slice; none is in a selected timeline test file.

Tests run:
- Live inventory: `CampaignPlanner` is 2,875 lines.
- Target cluster maps 16 ordered pipeline calls to 25 private
  derivation/source helpers spanning timeline pressure families.

Behavior/schema changes:
None.

Outcome:
No timeline-pressure extraction has started.

Last completed slice:
Branch candidate-refresh derivation extraction published as `2a0ef9fe`:
`CampaignPlanner` shrank from 3,025 to 2,875 lines; focused, operational
feedback, branch-repair, file-backed, compile, and baseline-equivalence proof
passed; independent review was clean. Handoff published as `0fa48dfa`.

Next candidate:
Publish this selection note, run the focused timeline baseline, then perform a
mechanical ordered extraction.

Blocked:
No.

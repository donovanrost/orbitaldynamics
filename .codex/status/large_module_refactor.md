# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner timeline-pressure derivation orchestration extraction.

Status:
Implementation published as `085b76d9`; handoff publication pending.

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
- The full planner directory has five known baseline failures recorded by the
  preceding slice. Post-change result is the same 728/733 with the same five
  test names, values, and stacktraces.
- `strategy_recommendation_pressure_events_test.exs` passes its one test but
  `--warnings-as-errors` aborts afterward on two pre-existing `0.0` pattern
  warnings in the unchanged test source.
- Independent review was clean. No behavior, artifact, ordering, callback,
  policy, API, or ownership finding remains.

Tests run:
- Live inventory: `CampaignPlanner` is 2,875 lines.
- Target cluster maps 16 ordered pipeline calls to 25 private
  derivation/source helpers spanning timeline pressure families.
- Baseline complete `strategy_timeline_*` family: 87 passed with warnings as
  errors.
- Post-change complete `strategy_timeline_*` family: 87 passed with warnings as
  errors.
- Strict forced compile: 3,640 files clean with warnings as errors.
- File-backed facade coverage: 7 passed with warnings as errors.
- Recommendation-pressure coverage: 1 assertion passed, then the test command
  aborted on the two documented pre-existing test-source warnings.
- Full planner directory: 728/733 passed, matching the documented five-failure
  baseline exactly.
- Public `CampaignPlanner` function list matches selection commit `54560d8d`.
  Xref reports the new internal module has only the planner runtime caller.
- Format check and `git diff --check` passed. No old timeline derivation helper
  remains in the facade.
- `CampaignPlanner` shrank from 2,875 to 2,584 lines. The new internal timeline
  orchestration module is 255 lines.
- Independent reviewer reran the 87 timeline cases, 7 file-backed cases,
  warning-bearing recommendation assertion, 3,640-file forced compile, xref,
  formatting, and whitespace checks. Results matched primary proof.

Behavior/schema changes:
None.

Outcome:
The derived-branch pipeline now makes one ordered call to
`DerivedTimelinePressureBranches.build/3`. The new internal module owns the
exact prior-plan/mission-state source-report and report-to-branch sequence for
all eight timeline families; the facade no longer duplicates that
orchestration. Implementation published as `085b76d9`.

Last completed slice:
Timeline-pressure derivation orchestration extraction published as `085b76d9`:
`CampaignPlanner` shrank from 2,875 to 2,584 lines; focused, file-backed,
compile, and full planner baseline-equivalence proof passed; independent review
was clean.

Next candidate:
Publish this handoff, then refresh the remaining facade responsibilities and
select the next bounded extraction.

Blocked:
No.

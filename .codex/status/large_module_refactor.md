# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner objective-pressure derivation orchestration extraction.

Status:
Ready for implementation.

Selected slice:
Move the private prior-plan/mission-state score-term, objective-satisfaction,
objective-tradeoff, and constraint pressure orchestration from
`CampaignPlanner` into a new internal
`CampaignPlanner.DerivedObjectivePressureBranches` module with one ordered
`build/2` entry point.

Why this slice:
After the timeline extraction, `CampaignPlanner` remains the largest named
implementation hotspot at 2,584 lines and 199 private functions. The selected
eight-stage cluster is cohesive report-to-branch orchestration behind one
source-report owner and four existing family branch builders.

Current coupling/problem:
The public planner facade owns paired prior-plan and mission-state wrappers for
four objective/constraint pressure families. These helpers add no facade
policy; they only select report sources, derive rows, and delegate branch
construction.

Public facade to preserve:
`CampaignPlanner.strategy/1`, `strategy!/1`, file-backed entry points, branch
IDs/events/metadata, branch ordering and deduplication, scoring artifacts,
deterministic output, and all error behavior.

Likely files:
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/derived_objective_pressure_branches.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The planner’s derived-branch pipeline delegates the exact existing eight-stage
sequence to `DerivedObjectivePressureBranches.build/2`; the private wrapper
cluster is removed from the facade; public artifacts and ordering are
unchanged; focused objective/score tests pass to their live baseline; strict
compile and independent review are clean.

Verification gaps:
- Focused objective/score baseline is pending.
- The full planner directory has five known baseline failures; one readiness
  score assertion is adjacent to this responsibility and must remain identical.

Tests run:
- Live inventory: `CampaignPlanner` is 2,584 lines with 199 private functions.
- Target cluster is 8 ordered pipeline calls and 8 private helpers.

Behavior/schema changes:
None.

Outcome:
No objective-pressure extraction has started.

Last completed slice:
Timeline-pressure derivation orchestration extraction published as `085b76d9`:
`CampaignPlanner` shrank from 2,875 to 2,584 lines; focused, file-backed,
compile, and full planner baseline-equivalence proof passed; independent review
was clean. Handoff published as `b41c2aa6`.

Next candidate:
Publish this selection note, run the focused objective/score baseline, then
perform the mechanical ordered extraction.

Blocked:
No.

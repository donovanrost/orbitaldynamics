# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner objective-pressure derivation orchestration extraction.

Status:
Implementation published as `a4e917cc`; handoff publication pending.

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
- The full planner directory has five known baseline failures; one readiness
  score assertion is adjacent to this responsibility. Its isolated post-change
  result is identical: `risk_penalty` is `-100.0` while the stale assertion
  expects `-200.0`, with the same stacktrace.
- The full directory was not rerun because it was baseline-confirmed in the
  immediately preceding slice; focused and broader objective coverage is green.
- Independent review was clean. No API, artifact, determinism, ordering,
  ownership, or behavioral finding remains.

Tests run:
- Live inventory: `CampaignPlanner` is 2,584 lines with 199 private functions.
- Target cluster is 8 ordered pipeline calls and 8 private helpers.
- Baseline objective/score family: 57 passed with warnings as errors.
- Post-change objective/score family: 57 passed with warnings as errors.
- Strict forced compile: 3,641 files clean with warnings as errors.
- File-backed facade coverage: 7 passed with warnings as errors.
- Strategy recommendation explanation coverage: 3 passed with warnings as
  errors.
- Isolated adjacent readiness baseline failure reproduced exactly.
- Public `CampaignPlanner` function list matches selection commit `e117a9e3`.
  Xref reports the new internal module has only the planner runtime caller.
- Format check and `git diff --check` passed. No old objective/score derivation
  helper remains in the facade.
- `CampaignPlanner` shrank from 2,584 to 2,485 lines. The new internal objective
  orchestration module is 111 lines.
- Independent reviewer reran all focused, broader, isolated-baseline, compile,
  xref, formatting, and whitespace checks; results matched primary proof.

Behavior/schema changes:
None.

Outcome:
The derived-branch pipeline now makes one ordered call to
`DerivedObjectivePressureBranches.build/2`. The new internal module owns the
exact prior-plan/mission-state source-report and row-to-branch sequence for
score-term, objective-satisfaction, objective-tradeoff, and constraint
pressure. Implementation published as `a4e917cc`.

Last completed slice:
Objective-pressure derivation orchestration extraction published as
`a4e917cc`: `CampaignPlanner` shrank from 2,584 to 2,485 lines; focused,
file-backed, recommendation, compile, and adjacent baseline-equivalence proof
passed; independent review was clean.

Next candidate:
Publish this handoff, then refresh the remaining facade responsibilities and
select the next bounded extraction.

Blocked:
No.

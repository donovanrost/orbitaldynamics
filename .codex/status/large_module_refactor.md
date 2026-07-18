# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner review/readiness derivation orchestration extraction.

Status:
Ready for implementation.

Selected slice:
Move the private candidate-review, provider-counteroffer, validation,
operational-readiness, quality-gate, refresh-budget, and freshness pressure
orchestration from `CampaignPlanner` into a new internal
`CampaignPlanner.DerivedReviewReadinessPressureBranches` module with one
ordered `build/2` entry point.

Why this slice:
After the resource extraction, `CampaignPlanner` remains the largest named
implementation hotspot at 2,360 lines and 174 private functions. The selected
12-stage block is contiguous review/readiness report orchestration behind
dedicated source and branch owners.

Current coupling/problem:
The public planner facade owns 12 review/readiness wrappers that add no strategy
policy; they only select prior/mission reports and delegate branch
construction.

Public facade to preserve:
`CampaignPlanner.strategy/1`, `strategy!/1`, file-backed entry points, branch
IDs/events/metadata, branch ordering and deduplication, scoring artifacts,
deterministic output, and all error behavior.

Likely files:
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/derived_review_readiness_pressure_branches.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The planner’s derived-branch pipeline delegates the exact existing 12-stage
sequence to `DerivedReviewReadinessPressureBranches.build/2`; the private wrapper
cluster is removed from the facade; public artifacts and ordering are
unchanged; focused review/readiness tests pass to their live baseline; strict
compile and independent review are clean.

Verification gaps:
- Focused review/readiness baseline is pending.
- The full planner directory has five known baseline failures; readiness and
  refresh-budget cases are adjacent and must retain their exact observations.

Tests run:
- Live inventory: `CampaignPlanner` is 2,360 lines with 174 private functions.
- Target cluster is 12 ordered pipeline calls and 12 private helpers.

Behavior/schema changes:
None.

Outcome:
No review/readiness extraction has started.

Last completed slice:
Resource-pressure derivation orchestration extraction published as `287e3425`:
`CampaignPlanner` shrank from 2,413 to 2,360 lines; focused, file-backed,
compile, and adjacent baseline-equivalence proof passed; independent review was
clean. Handoff published as `139c6604`.

Next candidate:
Publish this selection note, run the focused review/readiness baseline, then
perform the mechanical ordered extraction.

Blocked:
No.

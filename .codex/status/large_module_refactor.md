# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner operational-review derivation orchestration extraction.

Status:
Ready for implementation.

Selected slice:
Move the private prior/mission operational-timeline and operator-review pressure
orchestration from `CampaignPlanner` into a new internal
`CampaignPlanner.DerivedOperationalReviewPressureBranches` module with one
ordered `build/3` entry point.

Why this slice:
After the activity extraction, `CampaignPlanner` remains the largest named
implementation hotspot at 2,113 lines and 152 private functions. The selected
four-stage block is contiguous review-source orchestration behind dedicated
timeline and operator-review owners.

Current coupling/problem:
The public planner facade still maps operational-timeline and operator-review
source rows into branches even though the family owners already define the
behavior.

Public facade to preserve:
`CampaignPlanner.strategy/1`, `strategy!/1`, file-backed entry points, branch
IDs/events/metadata, branch ordering and deduplication, scoring artifacts,
deterministic output, and all error behavior.

Likely files:
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/derived_operational_review_pressure_branches.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The planner’s derived-branch pipeline delegates the exact existing four-stage
sequence to `DerivedOperationalReviewPressureBranches.build/3`; the private wrapper
cluster is removed from the facade; public artifacts and ordering are
unchanged; focused operational-review tests pass to their live baseline; strict
compile and independent review are clean.

Verification gaps:
- Focused operational-review baseline is pending.
- The full planner directory retains five known baseline failures; none is in
  the selected focused files.

Tests run:
- Live inventory: `CampaignPlanner` is 2,113 lines with 152 private functions.
- Target cluster is 4 ordered pipeline calls and 4 private helpers.

Behavior/schema changes:
None.

Outcome:
No operational-review extraction has started.

Last completed slice:
Activity-pressure derivation orchestration extraction published as `ed8526d5`:
`CampaignPlanner` shrank from 2,233 to 2,113 lines; focused, file-backed, and
compile proof passed; independent review was clean. Handoff published as
`e419e271`.

Next candidate:
Publish this selection note, run the focused operational-review baseline, then
perform the mechanical ordered extraction.

Blocked:
No.

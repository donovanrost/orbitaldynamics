# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner activity-pressure derivation orchestration extraction.

Status:
Ready for implementation.

Selected slice:
Move the private planned-activity, proposed-contact, contact-intent/summary, and
realized-activity pressure orchestration from `CampaignPlanner` into a new
internal `CampaignPlanner.DerivedActivityPressureBranches` module with one
ordered `build/2` entry point.

Why this slice:
After the review/readiness extraction, `CampaignPlanner` remains the largest
named implementation hotspot at 2,233 lines and 162 private functions. The
selected ten-stage block is contiguous activity/contact artifact orchestration
behind dedicated source-row and pressure owners.

Current coupling/problem:
The public planner facade owns ten activity-pressure wrappers, including
contact-intent direct/summary identity handling, despite all behavior belonging
to existing activity/contact pressure owners.

Public facade to preserve:
`CampaignPlanner.strategy/1`, `strategy!/1`, file-backed entry points, branch
IDs/events/metadata, branch ordering and deduplication, scoring artifacts,
deterministic output, and all error behavior.

Likely files:
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/derived_activity_pressure_branches.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The planner’s derived-branch pipeline delegates the exact existing ten-stage
sequence to `DerivedActivityPressureBranches.build/2`; the private wrapper
cluster is removed from the facade; public artifacts and ordering are
unchanged; focused activity/contact tests pass to their live baseline; strict
compile and independent review are clean.

Verification gaps:
- Focused activity/contact baseline is pending.
- The full planner directory retains five known baseline failures; none is in
  the selected focused files.

Tests run:
- Live inventory: `CampaignPlanner` is 2,233 lines with 162 private functions.
- Target cluster is 10 ordered pipeline calls and 10 private helpers.

Behavior/schema changes:
None.

Outcome:
No activity-pressure extraction has started.

Last completed slice:
Review/readiness derivation orchestration extraction published as `6740eb4d`:
`CampaignPlanner` shrank from 2,360 to 2,233 lines; focused, file-backed,
compile, and adjacent baseline-equivalence proof passed; independent review was
clean. Handoff published as `f23acd85`.

Next candidate:
Publish this selection note, run the focused activity/contact baseline, then
perform the mechanical ordered extraction.

Blocked:
No.

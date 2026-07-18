# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner resource-pressure derivation orchestration extraction.

Status:
Ready for implementation.

Selected slice:
Move the private power, thermal, payload, antenna, resource-projection, and
resource-filter pressure orchestration from `CampaignPlanner` into a new
internal `CampaignPlanner.DerivedResourcePressureBranches` module with one
ordered `build/3` entry point.

Why this slice:
After the contact extraction, `CampaignPlanner` remains the largest named
implementation hotspot at 2,413 lines and 182 private functions. The selected
eight-stage block is contiguous resource branch/report orchestration behind
dedicated owners.

Current coupling/problem:
The public planner facade owns eight resource-pressure wrappers that add no
strategy policy; they only select mission constraints or prior/mission reports
and delegate branch construction.

Public facade to preserve:
`CampaignPlanner.strategy/1`, `strategy!/1`, file-backed entry points, branch
IDs/events/metadata, branch ordering and deduplication, scoring artifacts,
deterministic output, and all error behavior.

Likely files:
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/derived_resource_pressure_branches.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The planner’s derived-branch pipeline delegates the exact existing eight-stage
sequence to `DerivedResourcePressureBranches.build/3`; the private wrapper
cluster is removed from the facade; public artifacts and ordering are
unchanged; focused resource tests pass to their live baseline; strict
compile and independent review are clean.

Verification gaps:
- Focused resource baseline is pending.
- The full planner directory has five known baseline failures; the resource
  filter selector at `strategy_filter_link_pressure_test.exs:182` is adjacent
  and must remain identical.

Tests run:
- Live inventory: `CampaignPlanner` is 2,413 lines with 182 private functions.
- Target cluster is 8 ordered pipeline calls and 8 private helpers.

Behavior/schema changes:
None.

Outcome:
No resource-pressure extraction has started.

Last completed slice:
Contact-pressure derivation orchestration extraction published as `c9bf75e0`:
`CampaignPlanner` shrank from 2,485 to 2,413 lines; focused, file-backed,
compile, and adjacent baseline-equivalence proof passed; independent review was
clean. Handoff published as `b682295d`.

Next candidate:
Publish this selection note, run the focused resource baseline, then perform
the mechanical ordered extraction.

Blocked:
No.

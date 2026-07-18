# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner resource-pressure derivation orchestration extraction.

Status:
Implementation published as `287e3425`; handoff publication pending.

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
- The full planner directory has five known baseline failures; the resource
  filter selector at `strategy_filter_link_pressure_test.exs:182` is adjacent
  and its post-change `List.first(nil)` failure is identical through the line
  241 assertion stacktrace.
- The full directory was not rerun; focused derivation/resource and
  file-backed coverage is green.
- Independent review was clean. No API, artifact, determinism, ordering,
  policy, ownership, error-behavior, or behavioral finding remains.

Tests run:
- Live inventory: `CampaignPlanner` is 2,413 lines with 182 private functions.
- Target cluster is 8 ordered pipeline calls and 8 private helpers.
- Baseline focused resource/branch-derivation coverage: 10 passed with warnings
  as errors.
- Post-change focused resource/branch-derivation coverage: 10 passed with
  warnings as errors.
- Strict forced compile: 3,643 files clean with warnings as errors.
- File-backed facade coverage: 7 passed with warnings as errors.
- Adjacent resource-filter baseline failure reproduced exactly.
- Public `CampaignPlanner` function list matches selection commit `990c5327`.
  Xref reports the new internal module has only the planner runtime caller.
- Format check and `git diff --check` passed. No old selected resource helper
  remains in the facade.
- `CampaignPlanner` shrank from 2,413 to 2,360 lines. The new internal resource
  orchestration module is 47 lines.
- Independent reviewer reran all focused, file-backed, adjacent-baseline,
  compile, xref, formatting, and whitespace checks; results matched primary
  proof.

Behavior/schema changes:
None.

Outcome:
The derived-branch pipeline now makes one ordered call to
`DerivedResourcePressureBranches.build/3`. The new internal module owns the
exact mission constraint, prior/mission resource-projection, and prior/mission
resource-filter branch sequence. Implementation published as `287e3425`.

Last completed slice:
Resource-pressure derivation orchestration extraction published as `287e3425`:
`CampaignPlanner` shrank from 2,413 to 2,360 lines; focused, file-backed,
compile, and adjacent baseline-equivalence proof passed; independent review was
clean.

Next candidate:
Publish this handoff, then refresh the remaining facade responsibilities and
select the next bounded extraction.

Blocked:
No.

# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner activity-pressure derivation orchestration extraction.

Status:
Implementation published as `ed8526d5`; handoff publication pending.

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
- The full planner directory retains five known baseline failures; none is in
  the selected focused files.
- The full directory was not rerun; focused and file-backed coverage is green.
- Independent review was clean. No API, artifact, determinism, ordering,
  identity, ownership, error-behavior, or behavioral finding remains.

Tests run:
- Live inventory: `CampaignPlanner` is 2,233 lines with 162 private functions.
- Target cluster is 10 ordered pipeline calls and 10 private helpers.
- Baseline focused activity/contact family: 15 passed with warnings as errors.
- Post-change focused activity/contact family: 15 passed with warnings as
  errors.
- Strict forced compile: 3,645 files clean with warnings as errors.
- File-backed facade coverage: 7 passed with warnings as errors.
- Public `CampaignPlanner` function list matches selection commit `eb1b33cd`.
  Xref reports the new internal module has only the planner runtime caller.
- Format, new-file whitespace, and `git diff --check` passed. No old selected
  activity helper remains in the facade.
- `CampaignPlanner` shrank from 2,233 to 2,113 lines. The new internal activity
  orchestration module is 101 lines.
- Independent reviewer reran the 15 focused cases, 7 file-backed cases,
  3,645-file compile, public-def, xref, formatting, diff, and new-file checks;
  results matched primary proof.

Behavior/schema changes:
None.

Outcome:
The derived-branch pipeline now makes one ordered call to
`DerivedActivityPressureBranches.build/2`. The new internal module owns the
exact planned/proposed, contact-intent direct/summary, and realized-activity
source-to-branch sequence. Implementation published as `ed8526d5`.

Last completed slice:
Activity-pressure derivation orchestration extraction published as `ed8526d5`:
`CampaignPlanner` shrank from 2,233 to 2,113 lines; focused, file-backed, and
compile proof passed; independent review was clean.

Next candidate:
Publish this handoff, then refresh the remaining facade responsibilities and
select the next bounded extraction.

Blocked:
No.

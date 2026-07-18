# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner operational-review derivation orchestration extraction.

Status:
Implementation published as `a5ae4f60`; handoff publication pending.

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
- The full planner directory retains five known baseline failures; none is in
  the selected focused files.
- The full directory was not rerun; focused and file-backed coverage is green.
- Independent review was clean. No API, artifact, determinism, ordering,
  ownership, error-behavior, or behavioral finding remains.

Tests run:
- Live inventory: `CampaignPlanner` is 2,113 lines with 152 private functions.
- Target cluster is 4 ordered pipeline calls and 4 private helpers.
- Baseline focused operational-review family: 14 passed with warnings as
  errors.
- Post-change focused operational-review family: 14 passed with warnings as
  errors.
- Strict forced compile: 3,646 files clean with warnings as errors.
- File-backed facade coverage: 7 passed with warnings as errors.
- Public `CampaignPlanner` function list matches selection commit `f87eb8cd`.
  Xref reports the new internal module has only the planner runtime caller.
- Format, new-file whitespace, and `git diff --check` passed. No old selected
  operational-review helper remains in the facade.
- `CampaignPlanner` shrank from 2,113 to 2,064 lines. The new internal
  operational-review orchestration module is 55 lines.
- Independent reviewer reran the 14 focused cases, 7 file-backed cases,
  3,646-file compile, public-def, xref, formatting, diff, and new-file checks;
  results matched primary proof.

Behavior/schema changes:
None.

Outcome:
The derived-branch pipeline now makes one ordered call to
`DerivedOperationalReviewPressureBranches.build/3`. The new internal module
owns the exact prior/mission operational-timeline and operator-review
source-to-branch sequence. Implementation published as `a5ae4f60`.

Last completed slice:
Operational-review derivation orchestration extraction published as
`a5ae4f60`: `CampaignPlanner` shrank from 2,113 to 2,064 lines; focused,
file-backed, and compile proof passed; independent review was clean.

Next candidate:
Publish this handoff, then refresh the remaining facade responsibilities and
select the next bounded extraction.

Blocked:
No.

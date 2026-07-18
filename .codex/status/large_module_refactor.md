# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner contact-pressure derivation orchestration extraction.

Status:
Implementation published as `c9bf75e0`; handoff publication pending.

Selected slice:
Move the private prior-plan/mission-state contact filter, contention,
contention-resolution, allocation-report, and allocation-summary pressure
orchestration from `CampaignPlanner` into a new internal
`CampaignPlanner.DerivedContactPressureBranches` module with one ordered
`build/2` entry point.

Why this slice:
After the objective extraction, `CampaignPlanner` remains the largest named
implementation hotspot at 2,485 lines and 191 private functions. The selected
nine-stage cluster is contiguous, cohesive report-to-branch orchestration
behind dedicated contact source and branch owners.

Current coupling/problem:
The public planner facade owns nine contact-pressure wrappers that add no
strategy policy; they only select prior/mission reports and delegate contact
branch construction.

Public facade to preserve:
`CampaignPlanner.strategy/1`, `strategy!/1`, file-backed entry points, branch
IDs/events/metadata, branch ordering and deduplication, scoring artifacts,
deterministic output, and all error behavior.

Likely files:
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/derived_contact_pressure_branches.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The planner’s derived-branch pipeline delegates the exact existing nine-stage
sequence to `DerivedContactPressureBranches.build/2`; the private wrapper
cluster is removed from the facade; public artifacts and ordering are
unchanged; focused contact tests pass to their live baseline; strict
compile and independent review are clean.

Verification gaps:
- The full planner directory has five known baseline failures; two filter-link
  selectors are adjacent to this responsibility. Both post-change failures are
  identical `List.first(nil)` observations with the same assertion stacktraces.
- The full directory was not rerun because it was baseline-confirmed two slices
  ago; focused and file-backed contact coverage is green.
- Independent review was clean. No API, artifact, determinism, ordering,
  ownership, error-behavior, or behavioral finding remains.

Tests run:
- Live inventory: `CampaignPlanner` is 2,485 lines with 191 private functions.
- Target cluster is 9 ordered pipeline calls and 9 private helpers.
- Baseline focused contact family: 14 passed with warnings as errors.
- Post-change focused contact family: 14 passed with warnings as errors.
- Strict forced compile: 3,642 files clean with warnings as errors.
- File-backed facade coverage: 7 passed with warnings as errors.
- Both adjacent filter-link baseline failures reproduced exactly.
- Public `CampaignPlanner` function list matches selection commit `1c2cd930`.
  Xref reports the new internal module has only the planner runtime caller.
- Format check and `git diff --check` passed. No old selected contact helper
  remains in the facade.
- `CampaignPlanner` shrank from 2,485 to 2,413 lines. The new internal contact
  orchestration module is 80 lines.
- Independent reviewer reran all focused, file-backed, adjacent-baseline,
  compile, xref, formatting, and whitespace checks; results matched primary
  proof.

Behavior/schema changes:
None.

Outcome:
The derived-branch pipeline now makes one ordered call to
`DerivedContactPressureBranches.build/2`. The new internal module owns the
exact source-report and report-to-branch sequence for contact filter,
contention, contention resolution, allocation reports, and allocation
summaries. Implementation published as `c9bf75e0`.

Last completed slice:
Contact-pressure derivation orchestration extraction published as `c9bf75e0`:
`CampaignPlanner` shrank from 2,485 to 2,413 lines; focused, file-backed,
compile, and adjacent baseline-equivalence proof passed; independent review was
clean.

Next candidate:
Publish this handoff, then refresh the remaining facade responsibilities and
select the next bounded extraction.

Blocked:
No.

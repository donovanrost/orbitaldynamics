# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner contact-pressure derivation orchestration extraction.

Status:
Ready for implementation.

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
- Focused contact baseline is pending.
- The full planner directory has five known baseline failures; two filter-link
  cases are adjacent to this responsibility and must remain identical.

Tests run:
- Live inventory: `CampaignPlanner` is 2,485 lines with 191 private functions.
- Target cluster is 9 ordered pipeline calls and 9 private helpers.

Behavior/schema changes:
None.

Outcome:
No contact-pressure extraction has started.

Last completed slice:
Objective-pressure derivation orchestration extraction published as
`a4e917cc`: `CampaignPlanner` shrank from 2,584 to 2,485 lines; focused,
file-backed, recommendation, compile, and adjacent baseline-equivalence proof
passed; independent review was clean. Handoff published as `a5a11372`.

Next candidate:
Publish this selection note, run the focused contact baseline, then perform the
mechanical ordered extraction.

Blocked:
No.

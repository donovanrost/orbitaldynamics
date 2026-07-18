# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner review/readiness derivation orchestration extraction.

Status:
Implementation published as `6740eb4d`; handoff published as `f23acd85`.

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
- The full planner directory has five known baseline failures; readiness and
  refresh-budget cases are adjacent. Both post-change failures are identical:
  readiness remains `-100.0` versus stale `-200.0`; refresh budget retains the
  same two source paths, counts, and branch-local pressure flags.
- The full directory was not rerun; focused and file-backed coverage is green.
- Independent review was clean. No API, artifact, determinism, ordering,
  ownership, error-behavior, or behavioral finding remains.

Tests run:
- Live inventory: `CampaignPlanner` is 2,360 lines with 174 private functions.
- Target cluster is 12 ordered pipeline calls and 12 private helpers.
- Baseline focused review/readiness family: 20 passed with warnings as errors.
- Post-change focused review/readiness family: 20 passed with warnings as
  errors.
- Strict forced compile: 3,644 files clean with warnings as errors.
- File-backed facade coverage: 7 passed with warnings as errors.
- Both adjacent baseline failures reproduced exactly.
- Public `CampaignPlanner` function list matches selection commit `511f0e80`.
  Xref reports the new internal module has only the planner runtime caller.
- Format, new-file whitespace, and `git diff --check` passed. No old selected
  review/readiness helper remains in the facade.
- `CampaignPlanner` shrank from 2,360 to 2,233 lines. The new internal
  review/readiness orchestration module is 124 lines.
- Independent reviewer reran the exact 20-test set, a broader 22-test superset,
  7 file-backed cases, both baseline failures, compile, xref, formatting, diff,
  and new-file checks; results matched primary proof.

Behavior/schema changes:
None.

Outcome:
The derived-branch pipeline now makes one ordered call to
`DerivedReviewReadinessPressureBranches.build/2`. The new internal module owns
the exact candidate/provider, validation, readiness/quality, and refresh-health
source-to-branch sequence. Implementation published as `6740eb4d`.

Last completed slice:
Review/readiness derivation orchestration extraction published as `6740eb4d`:
`CampaignPlanner` shrank from 2,360 to 2,233 lines; focused, file-backed,
compile, and adjacent baseline-equivalence proof passed; independent review was
clean. Handoff published as `f23acd85`.

Next candidate:
Extract the ten contiguous planned-activity, proposed-contact,
contact-intent/summary, and realized-activity pressure stages into an ordered
`DerivedActivityPressureBranches.build/2` owner. Focused tests should cover
contact-intent, realized feedback/status, operational-timeline source rows, and
the file-backed facade.

Blocked:
No.

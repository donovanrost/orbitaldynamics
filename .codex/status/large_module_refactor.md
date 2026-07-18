# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner derived-branch generation boundary extraction.

Status:
Implementation published as `1841dc35`; handoff publication pending.

Selected slice:
Move the two private `maybe_add_derived_branches/6` clauses and their remaining
thin family wrappers from `CampaignPlanner` into a new internal
`CampaignPlanner.DerivedBranchOrchestration.merge/6` boundary.

Why this slice:
After the station extraction, `CampaignPlanner` is 2,023 lines with 144 private
functions. Repeated family extractions have made the remaining derived-branch
pipeline a cohesive V3 generation boundary composed almost entirely of
internal owners.

Current coupling/problem:
The public planner facade still owns derive-disabled handling, the complete
family ordering, final contact-intent deduplication, merge policy, and thin
wrappers for degraded/ground/feedback/link/fuel/target/latency/downlink
families.

Public facade to preserve:
`CampaignPlanner.strategy/1`, `strategy!/1`, file-backed entry points, branch
IDs/events/metadata, branch ordering and deduplication, scoring artifacts,
deterministic output, and all error behavior.

Likely files:
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/derived_branch_orchestration.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
Strategy normalization delegates derived-branch generation to
`DerivedBranchOrchestration.merge/6`; disabled behavior, exact family ordering,
deduplication, merge policy, public artifacts, and errors are unchanged;
focused and full planner tests match live baseline; strict compile and
independent review are clean.

Verification gaps:
- The full planner directory has five previously documented failures that must
  retain their exact observations. Post-change result is the same 728/733 with
  identical test names, values, and stacktraces.
- Independent review was clean. No API, artifact, determinism, ordering,
  policy/provenance, ownership, error-behavior, or behavioral finding remains.

Tests run:
- Live inventory: `CampaignPlanner` is 2,023 lines with 144 private functions.
- Target includes the two orchestration clauses and nine remaining thin family
  helpers.
- Baseline full planner directory: 728/733 passed with the five documented
  failures.
- Post-change full planner directory: 728/733 passed with the same five
  failures and observations.
- Focused green orchestration subset: 107 passed with warnings as errors before
  and after extraction.
- Strict forced compile: 3,648 files clean with warnings as errors.
- Public `CampaignPlanner` function list matches selection commit `ce6665f5`.
  Xref reports the new internal module has only the planner runtime caller.
- Format, new-file whitespace, and `git diff --check` passed. No old
  orchestration or selected thin helper remains in the facade.
- `CampaignPlanner` shrank from 2,023 to 1,894 lines. The new internal
  orchestration module is 94 lines.
- Independent reviewer reran the exact 107-test subset, 3,648-file compile,
  public-def, xref, formatting, diff, and new-file checks; results matched
  primary proof.

Behavior/schema changes:
None.

Outcome:
Strategy normalization now delegates one call to
`DerivedBranchOrchestration.merge/6`. The new owner preserves derive-disabled
behavior, exact family order, link-capacity transforms, contact-intent
deduplication, and final policy-aware branch merging. Implementation published
as `1841dc35`.

Last completed slice:
Derived-branch generation boundary extraction published as `1841dc35`:
`CampaignPlanner` shrank from 2,023 to 1,894 lines; focused, full-baseline, and
compile proof passed; independent review was clean.

Next candidate:
Publish this handoff, then refresh the remaining facade responsibilities and
select the next bounded extraction.

Blocked:
No.

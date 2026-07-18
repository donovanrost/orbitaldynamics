# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner branch candidate-refresh derivation extraction.

Status:
Implementation published as `2a0ef9fe`; handoff publication pending.

Selected slice:
Move `derive_branch_candidate_refresh_request/2` and its owned refresh-input
helpers from `CampaignPlanner` into existing internal module
`CampaignPlanner.BranchCandidateRefresh`. Keep strategy entry points and result
artifacts unchanged.

Why this slice:
Live hotspot inventory shows `CampaignPlanner` remains 3,025 lines with 242
private functions while candidate-refresh and operator-review facades are
already 524 and 505 lines. The selected ~140-line cluster is cohesive, and all
of its assembly behavior belongs with branch refresh derivation; underlying
behaviors already live in dedicated internal modules.

Current coupling/problem:
The public planner facade still assembles accepted state, targets, ground
network, policies, source reports, operational feedback, and resource summaries
for a branch refresh request despite `BranchCandidateRefresh` owning request
selection and execution.

Public facade to preserve:
`CampaignPlanner.strategy/1`, `strategy!/1`, file-backed entry points, branch
refresh request maps, candidate-refresh artifacts, deterministic ordering, and
all error behavior.

Likely files:
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/branch_candidate_refresh.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
`CampaignPlanner` passes `&BranchCandidateRefresh.derive/2` at both existing
call sites; derivation and owned helpers live in the internal module;
baseline request/artifact behavior is unchanged; focused and broader planner
tests pass to their live baseline; review finds no blocker.

Verification gaps:
- One relevant baseline test is already stale on clean `d02cbca2`:
  `strategy_branch_generated_candidate_refresh_test.exs:269` reports current
  branch-local refresh-budget pressure as true while the assertion expects
  false. The isolated post-change observation is identical, including both
  source paths, all counts, and the three true pressure booleans.
- The full planner directory has four additional baseline failures in source
  report/filter/readiness assertions. All four reproduce identically in a
  detached worktree at selection commit `39702397`; this slice adds no failure.
- Independent review was clean. The reviewer found no public API, behavior,
  artifact, determinism, or ownership blocker.

Tests run:
- Initial helper counts classified four shared facade uses too narrowly. Strict
  compile exposed them before tests: branch evaluation now calls
  `BranchCandidateRefresh.operational_feedback/2`, while inherited refresh
  inputs call the established accepted-state, target, and ground-station owners
  directly. `derive_branch_candidate_refresh_request` has three moved clauses
  and two callback captures.
- Focused five-test green subset covering branch execution, source paths, rich
  mission state, shared candidates, and branch overrides: 5 passed with warnings
  as errors.
- Full six-test pair baseline: 5 passed, 1 pre-existing stale assertion failed
  as described above.
- Strict forced compile with warnings as errors: 3,639 files, clean after the
  shared-helper call sites and unused aliases were corrected.
- Operational-feedback telemetry refresh coverage: 20 passed with warnings as
  errors.
- Candidate-refresh branch-repair coverage: 2 passed with warnings as errors.
- Full planner directory: 728/733 passed; the known refresh-budget failure plus
  four unrelated failures. The four unrelated exact cases were rerun at
  `39702397` in an isolated build and failed with the same values and
  stacktraces.
- `git diff --check` passed. Xref reports
  `CampaignPlanner.BranchCandidateRefresh` has only the planner runtime caller.
- `CampaignPlanner` shrank from 3,025 to 2,875 lines; the internal
  `BranchCandidateRefresh` module is 182 lines.
- Independent reviewer reran the five green focused cases, the full six-test
  pair, the isolated known failure, 22 operational-feedback/branch-repair
  cases, 7 file-backed facade cases, and the 3,639-file forced compile. Results
  matched the primary proof and the review was clean.

Behavior/schema changes:
None.

Outcome:
Branch candidate-refresh request derivation, operational-feedback normalization,
and resource-summary assembly now live with `BranchCandidateRefresh`.
`CampaignPlanner` retains its public strategy facade and routes the two existing
derivation callbacks to the internal owner. Shared inherited-input callers use
the established accepted-state, target, and ground-station modules directly.
Implementation published as `2a0ef9fe`.

Last completed slice:
Branch candidate-refresh derivation extraction published as `2a0ef9fe`:
`CampaignPlanner` shrank from 3,025 to 2,875 lines; focused, operational
feedback, branch-repair, file-backed, compile, and baseline-equivalence proof
passed; independent review was clean.

Next candidate:
Publish this handoff, then refresh the hotspot inventory and select the next
responsibility-focused `CampaignPlanner` extraction.

Blocked:
No.

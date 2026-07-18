# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner V1 build-orchestration boundary extraction.

Status:
Implementation published as `6fc2e3e4`; handoff publication pending.

Selected slice:
Move the body of public `CampaignPlanner.build/2` and its V1-only generation,
filtering, ranking, reporting, and metadata helpers into an internal
`CampaignPlanner.BuildOrchestration.build/3` boundary.

Why this slice:
After V2 repair-execution and V3 branch-evaluation extractions,
`CampaignPlanner` is 1,443 lines. The public 156-line V1 `build/2` entry point
still owns the full candidate-to-artifact pipeline and is the last generation
entry point without a cohesive orchestration owner.

Current coupling/problem:
The facade directly coordinates candidate generation, station/resource/contact
filters, contention/allocation, scenario ranking, contact intents, link and
resource reports, objective and timeline reports, optimizer contract, local
constraints, warnings, metadata, and `BuildArtifact` assembly.

Public facade to preserve:
`CampaignPlanner.build/2`, all V1 artifact fields and ordering, generated-time
semantics, contact/resource/timeline/objective reports, optimizer contract,
deterministic output for fixed inputs, and all error behavior.

Likely files:
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/build_orchestration.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
Public `build/2` keeps option validation and delegates to
`BuildOrchestration.build/3`; V1-only helpers move with the pipeline while
shared V2 helpers remain in the facade; public artifacts and errors are
unchanged; focused and full planner tests match live baseline; strict compile
and independent review are clean.

Verification gaps:
- The full planner directory retains the five previously documented failures:
  728/733 passed with the same test names, values, and stack locations.
- Independent review found and then verified the fix for one evaluation-order
  issue. No code, API, artifact, determinism, ordering, ownership,
  error-behavior, or behavioral finding remains.

Tests run:
- Baseline and post-change focused V1 subset: 34 passed with warnings as
  errors.
- Post-change full planner directory: 728/733 passed with the same five
  documented failures and observations as the live baseline.
- Strict forced compile: 3,652 files clean with warnings as errors.
- Public `CampaignPlanner` definitions match selection commit `f727c1f9`.
  Xref reports it as the only runtime caller of `BuildOrchestration`.
- The shared contention policy has exactly the two intended callers:
  `CampaignPlanner` for V2 repair and `BuildOrchestration` for V1.
- Format, tracked and new-file whitespace, and `git diff --check` passed.
  Selected V1-only helpers are absent from the facade.
- `CampaignPlanner` shrank from 1,443 to 1,078 lines.
  `BuildOrchestration` is 312 lines after the evaluation-order fix; the shared
  contention policy owner is 24 lines.
- Independent review caught inlined report computation changing malformed-input
  error precedence. The final code restores the exact flow, precondition,
  integrity, objective, tradeoff, and optimizer evaluation order. The reviewer
  reran 34/34 and the 3,652-file compile on the corrected state.

Behavior/schema changes:
None intended.

Outcome:
Public `build/2` now retains option and generated-time evaluation before
delegating to `BuildOrchestration.build/3`. V1 artifact construction and shared
V2 contention policy behavior are preserved. Implementation published as
`6fc2e3e4`.

Last completed slice:
V3 branch-evaluation boundary published as implementation `3fecf5e0` and
handoff `078c673f`: `CampaignPlanner` shrank from 1,802 to 1,443 lines; focused
55/55, full-baseline, and 3,650-file compile proof passed; independent review
was clean.

Next candidate:
Publish this handoff, then refresh the remaining normalization and V2 reporting
responsibilities before selecting the next bounded extraction.

Blocked:
No.

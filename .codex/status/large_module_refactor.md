# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner V1 build-orchestration boundary extraction.

Status:
Slice selected; implementation not started.

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
- The full planner directory has five previously documented failures. The
  post-change run must retain the same 728/733 result and observations.
- The exact focused V1 build baseline still needs to be captured.

Tests run:
- Live inventory: `CampaignPlanner` is 1,443 lines.
- The public `build/2` body spans 156 lines and is followed by a cohesive set
  of V1-only private helpers.
- Shared V2 link-capacity, resource-projection, scoring, and downlink helpers
  are excluded from the extraction.
- No runtime code has changed in this slice.

Behavior/schema changes:
None intended.

Outcome:
Pending.

Last completed slice:
V3 branch-evaluation boundary published as implementation `3fecf5e0` and
handoff `078c673f`: `CampaignPlanner` shrank from 1,802 to 1,443 lines; focused
55/55, full-baseline, and 3,650-file compile proof passed; independent review
was clean.

Next candidate:
Implement and verify the selected V1 build-orchestration boundary.

Blocked:
No.

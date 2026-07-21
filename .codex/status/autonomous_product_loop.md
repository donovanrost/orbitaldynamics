# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Expose persisted backend-comparison acceptance through the public API.

Status:
Implemented, parent-reviewed, and verified. Publish pending.

Why this slice:
The checkout already has exact, schema-linted scalar/Nx/EXLA benchmark fixtures
and internal acceptance logic that distinguishes correctness-only evidence from
supported speedup claims. Product consumers currently must reach into
`OrbitalDynamics.Study.Benchmark.Report` or invoke a Mix task to obtain that
interpretation; the canonical `OrbitalDynamics` facade does not expose it.

Files changed:
- `lib/orbital_dynamics.ex`
- `lib/orbital_dynamics/study/benchmark/report.ex`
- `test/orbital_dynamics/study/benchmark/report_test.exs`
- `test/orbital_dynamics/capabilities_test.exs`
- `docs/feature_set/capability_map/03_propagation_and_force_models.md`
- `.codex/status/autonomous_product_loop.md`

Behavior changed:
`OrbitalDynamics.study_benchmark_summary/2` now interprets a persisted benchmark
artifact through the existing median, reference-match, speedup, operational
scale, and backend-acceptance policy logic. The reporting capability catalog
declares this public facade.

Public proof:
The facade regression consumes the checked-in, schema-linted
`study_results/nx_study_benchmark.json` artifact. It proves all six comparison
groups match the scalar baseline, the 2,000-case EXLA group carries supported
speedup evidence, and the slower Nx group remains correctness-only.

Docs read/changed:
- Read `docs/feature_set/completeness_levels/06_mature_operational_platform.md`.
- Read `docs/feature_set/definition_of_feature_complete.md`.
- Read `docs/feature_set/current_capability_snapshot.md`.
- Read `docs/feature_set/recommended_roadmap.md`.
- Read `docs/feature_set/capability_map/03_propagation_and_force_models.md`.

Verification:
- Benchmark/report/fixture/policy/task/capability set: `44 passed`.
- Validation and schema directories: green.
- Full `mix test --timeout 180000`: `3452 passed`.
- Changed Elixir files are formatted; `git diff --check` passes.

Artifact regeneration:
Not expected: this slice consumes the existing checked-in
`study_results/nx_study_benchmark.json` comparison artifact.

Level 6 pillar advanced:
Replaceable numerical backends with explicit, consumable acceptance evidence.

Parent review:
No must-fix findings. The public function delegates to the established report
logic, consumes a supplied artifact without IO or rerunning studies, and does
not turn correctness-only evidence into a speedup claim. The regression uses
the existing exact benchmark fixture and checks reference, accepted-speedup,
and correctness-only outcomes. Sidecar delegation remains unavailable under
the active runtime policy, so the parent performed review and publish checks.

Previous published slice:
- `0763ccbd` Block unavailable station calendars (`3451 passed`).

Current publish:
- Commit pending.

Remaining maturity gaps:
- Continue contact/resource/readiness selection only where canonical artifacts
  expose unambiguous blocking evidence.
- Continue branch-local realized-feedback depth where public replay preserves a
  decision-safe signal.
- Continue deeper numerical/backend and resource-model maturity separately.

Blocked:
Not blocked.

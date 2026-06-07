# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
ResourceSummary roll-forward battery energy alias metadata.

Status:
Implemented, verified, reviewed, and ready for commit/push.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/resource_summary.ex`
- `test/orbital_dynamics/resource_summary_test.exs`
- `docs/feature_set/capability_map/06_spacecraft_and_payload_modeling.md`

Slice-selection note:
Selected slice:
Expose the selected-activity battery consumed/generated alias paths used by
`ResourceSummary.roll_forward/3` through facade capability metadata.

Why this slice:
The previous slice proved the `ResourceSummary` facade carries battery
consumed/generated/delta/SOC/depletion evidence through
`ResourceProjection.flow_report/3`, but callers inspecting
`ResourceSummary.capabilities/0` still could not see the activity input paths
that feed that battery roll-forward.

Level 6 pillar advanced:
Fleet-level resource allocation behavior with explicit known limits.

Implementation notes:
- `ResourceSummary.capabilities/0` now exposes
  `roll_forward_battery_energy_consumed_paths` and
  `roll_forward_battery_energy_generated_paths`.
- The metadata delegates to `ResourceProjection.capabilities/0` so the facade
  stays aligned with the underlying selected-activity projection model.
- Focused tests verify representative direct and nested metadata aliases.
- The spacecraft/payload capability doc now says the ResourceSummary facade
  advertises those declared-energy paths.

Tests run:
- `mix test test/orbital_dynamics/resource_summary_test.exs`
- `git diff --check`

Docs/artifacts changed:
- `docs/feature_set/capability_map/06_spacecraft_and_payload_modeling.md`

Review:
- Read-only subagent review found one must-fix ledger mismatch.
- Fixed by updating this ledger with all changed files and verification.
- No code/doc blocker found. Residual risk is low: the test checks
  representative paths, while implementation delegates to `ResourceProjection`.

Remaining maturity gaps:
- Resource projection remains selected-activity, artifact-only evidence, not a
  calibrated continuous subsystem simulation.
- Broader resource/contact allocation hardening remains available in the guide.

Last commit:
`d40ac0debbda1e8305ad1f5415a979c97835ccfb` pushed to `origin/main` for
ResourceSummary selected-activity roll-forward battery evidence alignment.

Next candidate:
Continue from `docs/autonomous_work_guide.md`; likely next candidate is another
resource/contact allocation hardening gap unless live verification shows a
broken contract.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Blocked:
No.

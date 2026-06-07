# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
ResourceSummary roll-forward storage/downlink alias metadata.

Status:
Implemented, verified, reviewed, and ready for commit/push.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/resource_summary.ex`
- `test/orbital_dynamics/resource_summary_test.exs`
- `docs/feature_set/capability_map/06_spacecraft_and_payload_modeling.md`

Slice-selection note:
Selected slice:
Expose selected-activity storage-production, audit-only actual data-volume, and
downlink-throughput alias paths used by `ResourceSummary.roll_forward/3`
through facade capability metadata.

Why this slice:
The previous slice exposed battery energy input paths for the facade. The same
public preflight gap remained for storage and downlink inputs that already feed
the underlying `ResourceProjection.flow_report/3` model.

Level 6 pillar advanced:
Fleet-level resource allocation behavior with explicit known limits.

Implementation notes:
- `ResourceSummary.capabilities/0` now exposes
  `roll_forward_planned_data_volume_paths`,
  `roll_forward_actual_data_volume_paths`, and
  `roll_forward_downlink_throughput_paths`.
- The metadata delegates to `ResourceProjection.capabilities/0` so facade
  preflight metadata stays aligned with the underlying projection model.
- Focused tests verify representative direct, nested `metadata`, and
  `throughput_model` aliases.
- The spacecraft/payload capability doc now says the ResourceSummary facade
  advertises selected-activity aliases for planned storage production,
  audit-only actual data volume, downlink throughput, and battery energy.

Tests run:
- `mix test test/orbital_dynamics/resource_summary_test.exs`
- `git diff --check`

Docs/artifacts changed:
- `docs/feature_set/capability_map/06_spacecraft_and_payload_modeling.md`

Review:
- Read-only subagent review found one must-fix ledger mismatch.
- Fixed by updating this ledger with all changed files and verification.
- No code/doc blocker found. Reviewer also checked runtime metadata equality
  against `ResourceProjection.capabilities/0`.

Remaining maturity gaps:
- Resource projection remains selected-activity, artifact-only evidence, not a
  calibrated continuous subsystem simulation.
- Broader resource/contact allocation hardening remains available in the guide.

Last commit:
`2aea415eae81f94dd0d0baeb1669fe70956e7315` pushed to `origin/main` for
ResourceSummary roll-forward battery energy alias metadata.

Next candidate:
Continue from `docs/autonomous_work_guide.md`; likely next candidate is another
resource/contact allocation hardening gap unless live verification shows a
broken contract.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Blocked:
No.

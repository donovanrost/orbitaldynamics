# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
ResourceSummary selected-activity roll-forward battery evidence alignment.

Status:
Implemented, verified, reviewed, and ready for commit/push.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/resource_summary.ex`
- `test/orbital_dynamics/resource_summary_test.exs`
- `docs/feature_set/capability_map/06_spacecraft_and_payload_modeling.md`

Slice-selection note:
Selected slice:
Align `ResourceSummary.roll_forward/3` capability/test/docs expectations with
the existing battery-aware `ResourceProjection.flow_report/3` selected-activity
projection evidence.

Why this slice:
The active queue's early activity/timeline, allocation, readiness, and
validation examples are mostly implemented in the live checkout. The remaining
Level 6 gap called out by the capability snapshot is resource simulation depth.
`ResourceProjection` already emits battery-aware selected-flow evidence, but
the `ResourceSummary` facade still advertised/asserted a thin storage/downlink
handoff.

Level 6 pillar advanced:
Fleet-level resource allocation behavior with explicit known limits.

Implementation notes:
- Kept `:no_resource_time_propagation` in `ResourceSummary.capabilities/0` for
  compatibility, while adding more precise selected-activity battery projection
  boundary metadata.
- Added `:resource_summary_roll_forward_battery_flow_evidence` row semantics.
- Extended the public `ResourceSummary.roll_forward/3` facade test to assert
  battery consumed/generated/delta, projected SOC, peak overuse, and pressure
  routing through the compact flow summary and top-level facade.
- Updated the spacecraft/payload capability doc to describe facade-level
  storage/downlink/battery evidence and the declared-energy-only boundary.

Tests run:
- `mix test test/orbital_dynamics/resource_summary_test.exs`
- `git diff --check`

Docs/artifacts changed:
- `docs/feature_set/capability_map/06_spacecraft_and_payload_modeling.md`

Review:
- Read-only subagent review found one must-fix ledger mismatch and one
  compatibility risk.
- Fixed both by updating this ledger and preserving the old
  `:no_resource_time_propagation` capability atom.

Remaining maturity gaps:
- Resource projection remains selected-activity, artifact-only evidence, not a
  calibrated continuous subsystem simulation.
- Broader resource/contact allocation hardening remains available in the guide.

Last commit:
`a52c6e4` pushed to `origin/main` for long-running loop handoff alignment.

Next candidate:
Continue from `docs/autonomous_work_guide.md`; likely next candidate is another
resource/contact allocation hardening gap unless live verification shows a
broken contract.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Blocked:
No.

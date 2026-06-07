# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
ResourceSummary selected-activity alias row semantics.

Status:
Implemented, verified, reviewed, and ready for commit/push.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/resource_summary.ex`
- `test/orbital_dynamics/resource_summary_test.exs`
- `docs/feature_set/capability_map/06_spacecraft_and_payload_modeling.md`

Slice-selection note:
Selected slice:
Advertise the ResourceSummary roll-forward selected-activity alias metadata in
`row_semantics`, not only as top-level capability keys.

Why this slice:
The previous slices exposed storage/downlink/battery input path metadata
through `ResourceSummary.capabilities/0`. Callers that use `row_semantics` for
capability discovery still could not see that the facade advertises those
selected-activity alias groups.

Level 6 pillar advanced:
Fleet-level resource allocation behavior with explicit known limits.

Implementation notes:
- Added ResourceSummary row-semantic atoms for selected-activity
  storage/data-volume aliases, downlink-throughput aliases, and battery-energy
  aliases.
- Focused tests pin the new discovery atoms.
- The spacecraft/payload capability doc now says row semantics name the facade
  input-alias groups for discovery.

Tests run:
- `mix test test/orbital_dynamics/resource_summary_test.exs`
- `git diff --check`

Docs/artifacts changed:
- `docs/feature_set/capability_map/06_spacecraft_and_payload_modeling.md`

Review:
- Read-only subagent review found one must-fix ledger mismatch.
- Fixed by updating this ledger with all changed files and verification.
- No code/doc/test blocker found. Residual risk is low: new row-semantic atoms
  are public metadata expansion.

Remaining maturity gaps:
- Resource projection remains selected-activity, artifact-only evidence, not a
  calibrated continuous subsystem simulation.
- Broader resource/contact allocation hardening remains available in the guide.

Last commit:
`73734daa20bfab113c2cac8f9c81adaa11842b49` pushed to `origin/main` for
ResourceSummary roll-forward storage/downlink alias metadata.

Next candidate:
Continue from `docs/autonomous_work_guide.md`; likely next candidate is another
resource/contact allocation hardening gap unless live verification shows a
broken contract.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Blocked:
No.

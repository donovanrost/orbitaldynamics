# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Prefer blocking contact-allocation overlap evidence during resource projection.

Status:
Implemented, parent-reviewed, locally verified, and published locally.
Behavior commit: `53a4e3a`.

Files changed:
- Resource roll-forward behavior:
  `lib/orbital_dynamics/resource_projection.ex`
- Focused regression:
  `test/orbital_dynamics/resource_projection_test.exs`
- Ground-network capability docs:
  `docs/feature_set/capability_map/07_ground_network/03_contact_allocation.md`
- Ledger:
  `.codex/status/autonomous_product_loop.md`

Tests/checks run:
- `mix test test/orbital_dynamics/resource_projection_test.exs:3931`
- `mix test test/orbital_dynamics/resource_projection_test.exs`
- `mix format --check-formatted lib/orbital_dynamics/resource_projection.ex test/orbital_dynamics/resource_projection_test.exs`
- `git diff --check`

Behavior changed:
Resource projection now selects blocking contact-allocation evidence from
multiple station-calendar overlaps before allocated evidence. A contact with an
allocated overlap plus a later deferred or policy-blocked overlap is ignored for
storage/downlink roll-forward instead of relieving pressure based on provider
overlap ordering. The regression pins both the full
`resource_projection_report.v1` flow rows and the compact
`resource_projection_flow_summary.v1` ignored-reason counts.

Docs/artifacts changed:
Contact-allocation capability docs now state that resource projection chooses
blocking overlap allocation evidence before allocated evidence when multiple
station-calendar overlaps carry embedded allocation state. No schema exports
changed.

Level 6 pillar advanced:
Fleet-level resource/contact allocation behavior: branch-local and
Cadence-facing storage/downlink pressure cannot be hidden by order-dependent
provider overlap evidence.

Remaining maturity gaps:
- Continue converting artifact evidence into planner-visible selection,
  ranking, or branch-scoring effects where live code still leaves it passive.
- Add exact compatibility or stale-input challenge coverage only after verifying
  the target family is not already covered by current fixtures.
- Reassess the guide and current code for the next verified Level 6 gap before
  editing; do not rely on stale ledger candidates.

Last behavior commit:
`53a4e3a` Prefer blocking allocation overlap evidence.

Next candidate:
Recalibrate from live code. Resource/communications challenge fixtures remain
likely high value, but many resource-filter, allocation-summary, reservation,
and projection surfaces already have row-derived guards.

Blocked:
Not blocked.

Notes:
- Selection note: resource-filter and provider-reservation request summaries
  already had row-derived stale-summary checks, and resource projection already
  handled direct/nested/one-overlap allocation status. The remaining narrow gap
  was conflicting multi-overlap allocation evidence.
- Existing full-suite formatting drift remains isolated to distant regions of
  `test/orbital_dynamics/campaign_planner_test.exs`; this slice did not touch
  that file.

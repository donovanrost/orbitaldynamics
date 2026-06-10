# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Preserve wrapped station-calendar reservation expiration evidence in
link-capacity summaries.

Status:
Completed and pushed.

Files changed:
- Link capacity: `lib/orbital_dynamics/communications/link_capacity.ex`
- Link capacity tests:
  `test/orbital_dynamics/communications/link_capacity_test.exs`
- Ground-network docs:
  `docs/feature_set/capability_map/07_ground_network/02_link_capacity.md`
- Ledger: `.codex/status/autonomous_product_loop.md`

Tests run:
- `mix test test/orbital_dynamics/communications/link_capacity_test.exs:3182`
- `mix test test/orbital_dynamics/communications/link_capacity_test.exs:2948`
- `mix compile --warnings-as-errors`
- `git diff --check`

Docs/artifacts changed:
- Documented that link-capacity summaries read reservation-expiration aliases
  from wrapped `source_station_calendar_overlaps` rows emitted by upstream
  filtering, intent, or allocation handoffs.

Level 6 pillar advanced:
Fleet-level station-calendar/contact capacity behavior with Cadence-facing
review/import handoffs.

Slice selection note:
Selected slice: wrapped station-calendar reservation expiration in link-capacity
summaries.

Why this slice: LinkCapacity aggregates reservation-expiration seconds for
review/import capacity rows, but its source-calendar number helper only read
immediate source maps. Wrapped overlap rows could hide `expires_at` and related
hold-expiration aliases.

Level 6 pillar: Fleet-level station-calendar/contact capacity behavior and
Cadence-facing review/import handoffs.

Current evidence gap: Link-capacity report, operator-review, and Cadence-import
rows could lose reservation deadline evidence when provider calendar expiration
fields lived under wrapped `source_station_calendar_overlaps`.

Docs read:
`docs/feature_set/capability_map/07_ground_network/02_link_capacity.md`;
focused LinkCapacity code/tests.

Likely files: `lib/orbital_dynamics/communications/link_capacity.ex`;
`test/orbital_dynamics/communications/link_capacity_test.exs`;
`docs/feature_set/capability_map/07_ground_network/02_link_capacity.md`;
`.codex/status/autonomous_product_loop.md`.

Likely tests: wrapped-overlap reservation-expiration link-capacity regression;
existing reservation evidence capacity test; `mix compile --warnings-as-errors`;
`git diff --check`.

Definition of done: LinkCapacity extracts reservation expiration seconds from
direct, source-entry, direct-overlap, and wrapped-overlap evidence, and those
values survive capacity report, operator-review, and Cadence-import rows.

Slice result:
- Source station-calendar number extraction now uses bounded recursive lookup
  through direct rows, nested source entries, and wrapped station-calendar
  overlaps.
- Added a focused regression proving wrapped overlap expiration seconds preserve
  plural `station_reservation_expires_at_s` through link-capacity report,
  summary, operator review, and Cadence import rows.
- Existing station-reservation link-capacity evidence behavior remains green.

Last completed slice:
Preserved wrapped station-calendar reservation expiration evidence in
link-capacity summaries.

Last commit:
- Product: `9ad938e` Preserve wrapped reservation expirations in link capacity
- Ledger: pending

Remaining maturity gaps:
- Existing operator-review/Cadence-import schema validation still treats
  link-capacity `station_reservation_expires_at_s` review rows as scalar even
  though established link-capacity review/import rows carry lists; this slice
  preserved behavior and did not widen that schema contract.
- Continue reassessing queue-2 provider-shaped contact/replay hardening gaps now
  that major filtering/allocation/intent/capacity artifacts are present.
- Continue closing queue-3 quality/readiness and queue-4 branch-local handoff
  completeness gaps for artifact families not present in checked-in strategy
  artifacts.

Next candidate:
Reassess the queue after publishing; likely either the link-capacity
review/import reservation-expiration schema mismatch or a compact queue-4 replay
handoff gap if schema widening looks broader than one slice.

Blocked:
Not blocked.

Notes:
- Previous published slice: Product `715ed05`, Ledger `5f0e1f9`, final status
  `838e5d5`.
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.
- Sidecar delegation is unavailable in this runtime; parent performed the same
  bounded local review and mechanical publish scope.

# Autonomous Product Loop Status

Current slice:
Add link-capacity provider routing maps to compact summaries.

Status:
Implemented, verified, read-only reviewed, and reviewer finding fixed.

What changed:
`LinkCapacity.summary/1` now emits
`station_calendar_provider_ids_by_ground_station_id` and
`station_calendar_provider_entry_ids_by_ground_station_id` from direct
link-capacity summary rows plus nested source station-calendar evidence.
`link_capacity_summary.v1` now requires those routing maps, exports them in
JSON Schema, and validates the top-level provider/provider-entry ID lists
against the map values. Duplicate compact rows for the same ground station now
merge ID arrays instead of overwriting earlier row evidence, and
`station_count` now follows the existing schema definition as the unique
ground-station ID count. LinkCapacity capability metadata advertises the
compact provider-routing semantic, and link-capacity docs now describe the
routing-map handoff and validation boundary.

Why this slice:
`link_capacity_summary.v1` already derived top-level station-calendar provider
IDs and provider-entry IDs from link-capacity rows, and downstream
CandidateRefresh replay depends on compact link-capacity summaries preserving
provider routing. The compact summary lacked provider/provider-entry ID maps by
ground station, so schema validation could type-check those top-level lists but
could not independently cross-check them against compact routing evidence.

Files changed:
- `lib/orbital_dynamics/communications/link_capacity.ex`
- `lib/orbital_dynamics/schema.ex`
- `test/orbital_dynamics/communications/link_capacity_test.exs`
- `docs/feature_set/capability_map/07_ground_network/02_link_capacity.md`
- `docs/artifacts/field_families/v1_campaign_plan/link_capacity.md`
- `.codex/status/autonomous_product_loop.md`

Verification:
- `mix test test/orbital_dynamics/communications/link_capacity_test.exs:9 test/orbital_dynamics/communications/link_capacity_test.exs:545 test/orbital_dynamics/communications/link_capacity_test.exs:2825 test/orbital_dynamics/communications/link_capacity_test.exs:3093` -> 4 passed, 39 excluded.
- `mix test test/orbital_dynamics/communications/link_capacity_test.exs` -> 43 passed.
- `mix format lib/orbital_dynamics/communications/link_capacity.ex lib/orbital_dynamics/schema.ex test/orbital_dynamics/communications/link_capacity_test.exs --check-formatted` -> pass.
- `mix orbital_dynamics.schema.lint --all` -> pass.
- `git diff --check` -> pass.

Read-only review:
Sidecar `019e9cc2-18dc-79e0-82ea-e105f7a96765` found a duplicate-station
provider-routing merge bug in the first implementation. The parent fixed it by
merging duplicate station ID arrays in the shared station-entry helper and
adding a duplicate-station regression that validates the compact
`link_capacity_summary.v1` artifact. Focused and full LinkCapacity tests plus
schema lint/diff hygiene pass after the fix.

Implementation commit:
Pending.

Last completed implementation commit:
`366a3276d886fa8941ac4373944d0640f5add082` pushed to `origin/main`.

Last ledger correction commit:
`6a81ebda97a7e9ac96cafa6f035ea3e7b1da4f1f` pushed to `origin/main`.

Next candidate:
Continue the resource/communications allocation queue after this compact
link-capacity routing contract is committed and pushed.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.

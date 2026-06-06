# Autonomous Product Loop Status

Current slice:
Advertise provider-calendar provider ID routing in resource-flow summaries.

Status:
Implemented, verified, read-only reviewed, committed, and pushed.

What changed:
`ResourceProjection.capabilities/0` now advertises provider-calendar provider ID
routing for compact resource-flow pressure summaries. The primary
`resource_projection_flow_summary.v1` fixture now carries
`station_calendar_provider_id`, asserts
`resource_pressure_station_calendar_provider_ids_by_type`, and validates stale
provider-ID maps against row-derived values. The capability-map docs now mention
provider IDs alongside provider-entry IDs for provider adapter pressure queues.

Why this slice:
`ResourceProjection.flow_summary/1` already emits
`resource_pressure_station_calendar_provider_ids_by_type` when pressured
downlink flow rows carry `station_calendar_provider_id`, and the schema validates
that map. The main compact resource-flow test and docs only pin provider-entry
routing, so adapter queues have a weaker contract for provider namespace routing
than for provider entry routing.

Likely files:
- `lib/orbital_dynamics/resource_projection.ex`
- `test/orbital_dynamics/resource_projection_test.exs`
- `docs/feature_set/capability_map/06_spacecraft_and_payload_modeling.md`

Verification:
- `mix test test/orbital_dynamics/resource_projection_test.exs:6 test/orbital_dynamics/resource_projection_test.exs:4664`
- `mix test test/orbital_dynamics/resource_projection_test.exs`
- `mix orbital_dynamics.schema.lint --all`
- `mix format lib/orbital_dynamics/resource_projection.ex test/orbital_dynamics/resource_projection_test.exs --check-formatted`
- `git diff --check`

Read-only review:
Sidecar `019e9cac-a574-78e1-af4f-8f9c55502c68` reported no findings. It
confirmed the capability semantic, provider-ID fixture evidence, row-derived
stale-map validation, and docs were consistent. It also ran the focused
resource-projection selectors and scoped `git diff --check` successfully.

Implementation commit:
`3d7231772c1a60c54a5412d29a4a76d95f7676d6` pushed to `origin/main`.

Last completed implementation commit:
`3d7231772c1a60c54a5412d29a4a76d95f7676d6` pushed to `origin/main`.

Last ledger correction commit:
`d5be0456bea318cb2379a2c0ca19c10e748a6df6` pushed to `origin/main`.

Next candidate:
Continue the resource/communications allocation queue after this provider
adapter routing contract is pinned.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.

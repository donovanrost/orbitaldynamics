# Autonomous Product Loop Status

Current slice:
Artifact-only relay data-path summary.

Status:
Implementation, schema validation/export, reference count updates, focused
verification, schema lint, reviewer follow-up, and targeted docs are complete.
Final local review is complete. Publish is pending.

`LinkCapacity.relay_data_path_summary/2` and
`OrbitalDynamics.relay_data_path_summary/2` now emit
`relay_data_path_summary.v1` with deterministic route IDs, source spacecraft
IDs, relay-chain spacecraft IDs, ground-station IDs, ground-downlink contact
IDs, custody/latency/risk status counts, route IDs by status and ground station,
latency maxima, product/collection IDs, and explicit artifact-only assumptions.
The summary validates top-level counts, ID sets, route maps, latency maxima,
row status vocabularies, and relay-hop counts from the published rows. It does
not model crosslink visibility, schedule relay contacts, deliver custody
acknowledgements, reserve provider contacts, mutate schedules, or grant operator
authority.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `docs/feature_set/capability_map/07_ground_network/02_link_capacity.md`
- `docs/feature_set/capability_map/07_ground_network/06_status_summary.md`
- `docs/feature_set/capability_map/07_ground_network_and_communications_planning.md`
- `docs/mission_planning/high_fidelity/06_operational_concerns.md`
- `lib/orbital_dynamics.ex`
- `lib/orbital_dynamics/communications/link_capacity.ex`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/validation.ex`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `schemas/relay_data_path_summary.v1.schema.json`
- `study_results/capability_catalog_v1.json`
- `study_results/schema_migration_report_v1.json`
- `study_results/validation_reference_fixtures.json`
- `test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `test/orbital_dynamics/communications/link_capacity_test.exs`
- `test/orbital_dynamics/schema_test.exs`
- `test/orbital_dynamics/validation_test.exs`

Tests run:
- `mix format lib/orbital_dynamics/communications/link_capacity.ex lib/orbital_dynamics.ex lib/orbital_dynamics/schema.ex test/orbital_dynamics/communications/link_capacity_test.exs`
- `mix test test/orbital_dynamics/communications/link_capacity_test.exs:9 test/orbital_dynamics/communications/link_capacity_test.exs:293 --trace --seed 0`
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix format test/mix/tasks/orbital_dynamics.schema.export_test.exs test/orbital_dynamics/schema_test.exs lib/orbital_dynamics/validation.ex test/orbital_dynamics/validation_test.exs`
- `mix test test/orbital_dynamics/communications/link_capacity_test.exs:9 test/orbital_dynamics/communications/link_capacity_test.exs:293 test/orbital_dynamics/schema_test.exs:16089 test/orbital_dynamics/schema_test.exs:19864 test/orbital_dynamics/schema_test.exs:20174 test/orbital_dynamics/schema_test.exs:20201 test/mix/tasks/orbital_dynamics.schema.export_test.exs:40 test/mix/tasks/orbital_dynamics.schema.export_test.exs:5654 test/orbital_dynamics/validation_test.exs:57 test/orbital_dynamics/validation_test.exs:10103 test/orbital_dynamics/validation_test.exs:10188 --trace --seed 0`
- `mix format test/orbital_dynamics/schema_test.exs`
- `mix test test/orbital_dynamics/communications/link_capacity_test.exs:9 test/orbital_dynamics/communications/link_capacity_test.exs:293 test/orbital_dynamics/schema_test.exs:16089 test/orbital_dynamics/schema_test.exs:19851 test/orbital_dynamics/schema_test.exs:19872 test/orbital_dynamics/schema_test.exs:19959 test/orbital_dynamics/schema_test.exs:20182 test/orbital_dynamics/schema_test.exs:20209 test/mix/tasks/orbital_dynamics.schema.export_test.exs:40 test/mix/tasks/orbital_dynamics.schema.export_test.exs:5663 test/orbital_dynamics/validation_test.exs:57 test/orbital_dynamics/validation_test.exs:10103 test/orbital_dynamics/validation_test.exs:10188 --trace --seed 0`
- `mix orbital_dynamics.schema.lint --all`
- `git diff --check`

Review:
Initial reviewer found order-dependent generated relay route IDs and assumption
contract drift between executable validation and exported schema. Fixed by
deriving fallback route IDs from stable route evidence plus a SHA-256 digest,
adding regression coverage for reordered inputs, and making provider
reservation/custody acknowledgement limits explicit in both JSON Schema and
executable validation. Final local review checked the relay summary contract,
deterministic IDs, schema exports, generated fixture counts, docs, and ledger;
no remaining blocking issues found.

Docs/artifacts changed:
Targeted docs updated. Schema bundle, new individual schema export, schema
migration report, capability catalog, and validation reference fixture report
regenerated.

Last commit:
`9eb2742` added timeline publication summary artifact and was pushed to
`origin/main`.

Next candidate:
After review and publish, re-read the guide/ledger/live worktree and continue
with the highest-priority unimplemented typed activity, resource handoff, or
quality/readiness slice.

Blocked:
No.

Notes:
Treat current files as authoritative and do not revert unrelated changes.
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice.

# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Contact allocation capacity-pack summary capability assumptions.

Status:
Implemented, verified, reviewed, ready to commit and push.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `lib/orbital_dynamics/communications/contact_allocation.ex`
- `lib/orbital_dynamics/schema.ex`
- `test/orbital_dynamics/communications/contact_allocation_test.exs`
- `test/orbital_dynamics/schema_test.exs`
- `schemas/contact_allocation_capacity_pack_summary.v1.schema.json`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `study_results/contact_allocation_capacity_pack_summary_v1.json`
- `docs/feature_set/capability_map/07_ground_network/03_contact_allocation.md`
- `docs/mission_planning/high_fidelity/06_operational_concerns.md`

Slice-selection note:
Selected slice:
Emit and validate `ContactAllocation.capabilities/0` capacity-pack vocabulary
metadata inside `contact_allocation_capacity_pack_summary.v1` assumptions.

Why this slice:
The capacity-pack summary is the public artifact handoff for reduced station
capacity routing, but its assumptions only carried generic execution/source/
operator bounds. The capability metadata already advertises the row status
vocabularies and capacity requirement source vocabulary used to derive those
routes. Carrying those values in the artifact gives Cadence adapters and
fixture validators a machine-checkable contract without a separate capability
lookup.

Level 6 pillar advanced:
Durable schema-versioned communications artifacts and Cadence-facing allocation
handoff fidelity.

Implementation notes:
- `ContactAllocation.capacity_pack_summary/1` now emits capability-derived
  `capacity_pack_statuses`, `reduced_capacity_pack_statuses`,
  `required_capacity_fraction_source_values`, `required_capacity_value_paths`,
  and `default_required_capacity_value_paths` inside `assumptions`.
- `Schema.json_schema/1` exports optional exact `const` values for those
  assumption fields on `contact_allocation_capacity_pack_summary.v1`.
- `Schema.validate_artifact/1` rejects stale present values while preserving
  older artifacts that omit the optional metadata.
- The checked-in capacity-pack summary fixture and exported schema bundle were
  refreshed.

Tests run:
- `mix format lib/orbital_dynamics/communications/contact_allocation.ex lib/orbital_dynamics/schema.ex test/orbital_dynamics/communications/contact_allocation_test.exs test/orbital_dynamics/schema_test.exs`
- `mix test test/orbital_dynamics/communications/contact_allocation_test.exs`
- `mix test test/orbital_dynamics/communications/contact_allocation_test.exs:7339 test/orbital_dynamics/schema_test.exs:20541 test/mix/tasks/orbital_dynamics.schema.export_test.exs:2644`
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix orbital_dynamics.schema.lint --all`
- `git diff --check`

Review:
- Read-only reviewer Dalton found no blockers.
- Dalton confirmed the assumptions are additive, schema consts derive from
  `ContactAllocation.capabilities/0`, stale present values are rejected, omitted
  optional fields remain valid, and provider/schedule authority is unchanged.
- Reviewer-noted optional-field stale coverage was expanded to all new
  capability assumption fields.

Docs/artifacts changed:
- Refreshed `contact_allocation_capacity_pack_summary.v1` schema and the schema
  bundle.
- Refreshed `study_results/contact_allocation_capacity_pack_summary_v1.json`.
- Updated contact-allocation and operational-concerns docs to describe
  artifact-carried capacity-pack vocabulary assumptions.

Remaining maturity gaps:
- Contact allocation remains artifact-only and does not reserve provider time,
  mutate schedules, approve contacts, or add a link-budget model.
- Reservation-conflict and provider-reservation request summaries have adjacent
  vocabularies that may merit artifact-carried assumptions in later slices.

Last commit:
Pending.

Next candidate:
After review/publish, continue from the live guide/status and prefer another
narrow communications or resource artifact gap that can be made
machine-checkable without expanding authority.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Blocked:
No.

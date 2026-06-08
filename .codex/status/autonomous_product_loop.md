# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Contact-allocation capacity-pack direction routing.

Status:
Implemented, locally reviewed, parent-verified, and ready to publish. Compact
`contact_allocation_capacity_pack_summary.v1` artifacts now expose direction-keyed
capacity demand and contact-ID routing for all, selected, and deferred
capacity-pack contacts. Runtime validation accepts older artifacts that omit the
optional maps, but rejects stale present values by deriving them from the
included allocation rows.

Files changed:
- `docs/artifacts/field_families/candidate_refresh_artifact.md`
- `docs/feature_set/capability_map/07_ground_network/03_contact_allocation.md`
- `lib/orbital_dynamics/communications/contact_allocation.ex`
- `lib/orbital_dynamics/schema.ex`
- `schemas/contact_allocation_capacity_pack_summary.v1.schema.json`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `study_results/contact_allocation_capacity_pack_summary_v1.json`
- `test/orbital_dynamics/communications/contact_allocation_test.exs`
- `test/orbital_dynamics/schema_test.exs`
- `.codex/status/autonomous_product_loop.md`

Tests run:
- `mix format lib/orbital_dynamics/communications/contact_allocation.ex lib/orbital_dynamics/schema.ex test/orbital_dynamics/communications/contact_allocation_test.exs test/orbital_dynamics/schema_test.exs`
- `mix test test/orbital_dynamics/communications/contact_allocation_test.exs:7770 test/orbital_dynamics/schema_test.exs:21096` (2 passed)
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix test test/orbital_dynamics/communications/contact_allocation_test.exs:7770 test/orbital_dynamics/schema_test.exs:21096` (2 passed after export)
- `git diff --check`
- `mix orbital_dynamics.schema.lint --all` (154 files, 154 artifacts, status pass)
- `mix test test/orbital_dynamics/communications/contact_allocation_test.exs test/orbital_dynamics/schema_test.exs` (236 passed)
- `mix test` (3227 passed; known `:propagator_exit` test log observed and suite exited green)

Docs/artifacts changed:
- Updated contact-allocation and CandidateRefresh artifact-family docs to state
  that capacity-pack summaries preserve station and direction demand/contact-ID
  maps.
- Regenerated the checked-in capacity-pack summary fixture through the public
  `OrbitalDynamics.contact_allocation_capacity_pack_summary/1` facade.
- Regenerated full schema exports.

Local review:
- The initial CandidateRefresh contact-intent direction-routing candidate was
  already implemented in the current checkout, so this slice pivoted to the
  compact capacity-pack summary gap.
- The new maps are additive optional fields. Present values are checked against
  row-derived direction demand and row-derived direction contact IDs, preserving
  compatibility while preventing stale routing metadata.
- No subagent reviewer was spawned in this continuation because the available
  delegation tool requires an explicit user request for subagents in the current
  turn.

Level 6 pillar advanced:
Fleet-level resource/contact allocation and durable schema-versioned handoff
behavior. Branch-local capacity-pack review queues can now route reduced-capacity
contacts by direction without reopening the full allocation report.

Remaining maturity gaps:
Planner-visible allocation behavior still needs deeper integration with
provider-calendar capacity, reservation pressure, and approval/import authority
during candidate selection. Typed publication and lifecycle surfaces still need
broader operator-approval hardening beyond the already published slices.

Last commit:
`38500cc` Expose capacity-pack direction routing.

Next candidate:
Reassess Level 6 gaps from the guide/ledger. Likely candidates include
planner-visible reduced-capacity/contact-allocation behavior in branch-local
candidate refresh, or continued publication/lifecycle hardening around explicit
operator approval and downstream import authority.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Previous published slice:
- `38500cc` exposed capacity-pack direction routing.
- `7b02d2b` routed publication invalidation reasons.
- `f433cbf` preserved publication dependency lineage.
- `05a0f69` updated the precondition evidence handoff.
- `3818b51` preserved duplicate precondition evidence.
- `7dfb84a` updated the provider replay handoff.

Blocked:
No.

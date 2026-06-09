# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Preserve reduced-capacity pack direction routing on capacity-pack review rows.

Status:
Completed and pushed.

Files changed:
- Product: `lib/orbital_dynamics/operator_review.ex`
- Product: `lib/orbital_dynamics/cadence_import.ex`
- Product schema: `lib/orbital_dynamics/schema.ex`
- Product tests: `test/orbital_dynamics/operator_review_test.exs`
- Product tests: `test/orbital_dynamics/cadence_import_test.exs`
- Docs: `docs/feature_set/capability_map/07_ground_network/03_contact_allocation.md`
- Docs: `docs/artifacts/field_families/candidate_refresh_artifact.md`
- Schema exports: `schemas/*.schema.json` files changed by
  `mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- Ledger: `.codex/status/autonomous_product_loop.md`

Tests run:
- `mix test test/orbital_dynamics/operator_review_test.exs:7151 test/orbital_dynamics/operator_review_test.exs:19348`
- `mix test test/orbital_dynamics/operator_review_test.exs`
- `mix test test/orbital_dynamics/cadence_import_test.exs:12075 test/orbital_dynamics/cadence_import_test.exs:12252`
- `mix test test/orbital_dynamics/schema_test.exs:21345 test/orbital_dynamics/schema_test.exs:28932 test/orbital_dynamics/schema_test.exs:31476 test/orbital_dynamics/schema_test.exs:31552 test/mix/tasks/orbital_dynamics.schema.export_test.exs:2647`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs:2647`
- `mix format lib/orbital_dynamics/operator_review.ex lib/orbital_dynamics/cadence_import.ex lib/orbital_dynamics/schema.ex test/orbital_dynamics/operator_review_test.exs test/orbital_dynamics/cadence_import_test.exs --check-formatted`
- `mix compile --warnings-as-errors`
- `git diff --check`
- Attempted broader checks: `mix test test/orbital_dynamics/cadence_import_test.exs`
  still has a fixture-coverage failure for advertised summary import sources;
  `mix test test/orbital_dynamics/schema_test.exs` surfaced existing checked-in
  fixture regeneration drift outside this slice plus the schema-export drift
  fixed by this slice.

Docs/artifacts changed:
Updated contact-allocation capability docs and candidate-refresh field-family
docs to document row-level capacity-pack direction routing preservation.
Regenerated checked-in JSON Schema exports for the shared review/import row
properties.

Level 6 pillar advanced:
Resource and communications allocation semantics; approval-aware automation
boundaries and Cadence-facing review/import artifacts.

Last completed slice:
Preserved reduced-capacity pack direction routing on capacity-pack review and
Cadence import rows.

What changed:
- `contact_allocation_capacity_pack_review` rows now derive and expose
  all/selected/deferred contact IDs by direction plus required-capacity fraction
  maps by direction from embedded reduced-capacity pack source evidence.
- Cadence import rows copy those six direction maps to their own top-level
  adapter boundary while still preserving the nested `source_review_row`.
- Schema validation and checked-in JSON Schema exports cover the new optional
  row/source fields and reject stale row-level maps that diverge from
  `source_contact_allocation_capacity_pack`.
- Focused operator-review and Cadence-import tests cover standalone
  `contact_allocation_report.v1` and
  `contact_allocation_capacity_pack_summary.v1` fixture paths.
- Parent performed bounded local review and mechanical publish because no
  suitable subagent tool is available in this runtime.

Last commit:
- Product: `8c612e9` Preserve capacity pack direction handoffs
- Ledger: this handoff commit on `main`

Remaining maturity gaps:
- Continue making existing review evidence planner-visible through candidate
  selection, branch scoring, compatibility checks, and challenge fixtures.
- Continue closing queue-1 activity/timeline semantics where selected handoffs,
  operator review, import manifests, and schema exports do not preserve the same
  conflict evidence emitted by operational timeline integrity rows.
- Reassess whether the next highest-value gap is another activity/timeline
  handoff, resource/contact allocation semantics, or checked-in compatibility
  fixture coverage.

Next candidate:
Reassess the guide queue from current checkout and choose the next narrow Level
6 slice, likely in queue-1 activity/timeline handoff completeness or queue-2
remaining resource/contact allocation semantics. Candidate follow-up: decide
whether to address the broader Cadence import fixture coverage gap for
advertised summary sources before taking another schema-visible product slice.

Blocked:
Not blocked.

Notes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.
- Sidecar delegation is unavailable in this runtime; parent uses the same
  bounded review and mechanical publish scope.

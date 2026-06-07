# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Provider reservation request direction-station routing.

Status:
Implemented, verified, reviewed, and ready to commit.

Slice-selection note:
Selected slice:
Add direction-plus-ground-station contact-ID routing to
`contact_allocation_provider_reservation_request_summary.v1` for no-request,
request-ready, and review-required provider reservation groups.

Why this slice:
Provider-reservation request summaries already expose request/no-request/review
contact IDs by direction and request/review IDs by ground station. Adjacent
station-pressure and reservation-conflict summaries also expose direction plus
ground-station routing, which is more useful for adapter queues that split
provider reservation work by antenna and contact direction. Provider-request
summaries currently require consumers to recompute that nested routing from
rows.

Level 6 pillar:
Fleet-level resource, contact, station-calendar, and allocation behavior with
clear Cadence-facing no-provider-write handoff artifacts.

Implemented:
- Provider reservation request summaries expose row-derived no-request,
  request-ready, and review-required contact-ID maps by direction and ground
  station.
- Standalone provider-request schema validation rejects stale nested maps, and
  operator-review/Cadence-import handoff validation now validates those
  top-level nested maps as optional stable-ID array maps.
- OperatorReview aggregates the nested routing maps from source summaries, and
  CadenceImport preserves them at the manifest boundary.
- Checked-in schema exports, the provider-reservation request fixture, and
  capability docs were refreshed to describe the new routing without implying
  provider reservation execution, schedule mutation, or operator authority.

Verification:
- `mix format lib/orbital_dynamics/schema.ex test/orbital_dynamics/schema_test.exs`
- `mix format lib/orbital_dynamics/operator_review.ex lib/orbital_dynamics/cadence_import.ex test/orbital_dynamics/operator_review_test.exs test/orbital_dynamics/cadence_import_test.exs docs/feature_set/capability_map/07_ground_network/03_contact_allocation.md`
- `mix test test/orbital_dynamics/schema_test.exs:6200 test/orbital_dynamics/operator_review_test.exs:14828 test/orbital_dynamics/cadence_import_test.exs:2080 test/orbital_dynamics/communications/contact_allocation_test.exs:2661 test/orbital_dynamics/schema_test.exs:21168`
- `mix test test/orbital_dynamics/validation_test.exs:8851`
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix orbital_dynamics.schema.lint --all`
- `git diff --check`

Review:
- Read-only review found the initial embedded executable-validation gap for the
  new top-level operator-review/Cadence-import nested fields and a stale docs
  sentence. Both were fixed, and focused tests now cover the validator gap and
  top-level preservation.

Product commit:
- `272f302` (`Route provider reservation requests by direction station`)

Previous pushed slice:
Selected transition integrity evidence expansion landed in product commit
`feac470` and final pushed ledger commit `a77deeb`, with local and
`origin/main` verified at `a77deebe5abdcfaacb603ccf216588711625ef24`.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Blocked:
No.

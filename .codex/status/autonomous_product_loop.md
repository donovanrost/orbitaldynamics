# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
CandidateRefresh provider-reservation direction-station replay.

Status:
Completed locally; product commit created and handoff updated.

Slice-selection note:
Selected slice:
Preserve provider-reservation request/no-request/review contact-ID maps by
direction and ground station through CandidateRefresh source-report and compact
replay summaries.

Why this slice:
The provider-reservation request summary now exposes direction-plus-station
routing, but CandidateRefresh replay still lifts only flat direction maps and
request/review station maps. Branch-local queues that split provider reservation
work by antenna and direction still need to reopen source rows.

Level 6 pillar:
Fleet-level resource/contact/station-calendar/allocation behavior with
branch-local refreshed candidate evidence.

Current evidence gap:
`candidate_refresh.v1` source-report summaries and replay summaries do not
preserve provider-reservation request/no-request/review contact IDs by both
direction and ground station.

Docs to read:
- `docs/artifacts/field_families/candidate_refresh_artifact.md`
- `docs/feature_set/capability_map/06_spacecraft_and_payload_modeling.md`
- `docs/feature_set/capability_map/07_ground_network/03_contact_allocation.md`

Likely files:
- `lib/orbital_dynamics/candidate_refresh.ex`
- `lib/orbital_dynamics/schema.ex`
- `test/orbital_dynamics/candidate_refresh_test.exs`
- `test/orbital_dynamics/schema_test.exs`
- generated CandidateRefresh schemas and bundle as needed
- `docs/artifacts/field_families/candidate_refresh_artifact.md`
- `docs/feature_set/capability_map/06_spacecraft_and_payload_modeling.md`

Likely tests:
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:<provider reservation replay selector>`
- `mix test test/orbital_dynamics/schema_test.exs:<candidate refresh source-report selector>`
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix orbital_dynamics.schema.lint --all`
- `git diff --check`

Definition of done:
- CandidateRefresh source-report summaries preserve no-request/request/review
  contact-ID maps by direction and ground station.
- Compact provider-reservation request replay output exposes those nested maps
  without reopening source rows.
- Schema validation/export treats the new maps as optional nested stable-ID maps.
- Focused tests cover direct and wrapped provider-reservation summary replay.
- Docs describe branch-local direction/station routing without implying provider
  writes, schedule mutation, or operator authority.

Previous pushed slice:
Provider reservation request direction-station routing landed in product commit
`272f302` and final pushed ledger commit `b658d89`, with local and `origin/main`
verified at `b658d891992fb796e5aeef7f9126dcb7d2e83ee4`.

Completed slice:
CandidateRefresh provider-reservation direction-station replay landed in product
commit `968a25b`. CandidateRefresh source-report summaries and compact
contact-allocation replay now preserve provider-reservation no-request,
request-ready, and review-required contact-ID maps by direction and ground
station. Full-row provider-reservation summaries derive the nested maps from
rows, while wrapped compact summaries preserve explicit nested maps. Candidate
refresh provenance schema/export now exposes the nested maps as optional nested
stable-ID maps and executable validation rejects malformed nested stable IDs.
Docs describe branch-local station/direction routing without adding provider
reservation, schedule mutation, Cadence write, or operator authority.

Verification:
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:6933 test/orbital_dynamics/candidate_refresh_test.exs:7210 test/orbital_dynamics/schema_test.exs:15879`
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix orbital_dynamics.schema.lint --all`
- `git diff --check`

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Blocked:
No.

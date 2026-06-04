# Autonomous Product Loop Status

Current slice:
CandidateRefresh contact-intent replay direction/station routing.

Status:
Implemented and focused verification is passing locally; pending review and
publish. ContactIntent summaries now emit direction-and-ground-station routing
maps, and CandidateRefresh source-report/replay summaries preserve those maps
alongside compact direction routes that include station IDs, station-bucketed
contact IDs, capacity-pack contact IDs, and required-capacity fractions. Replay
remains artifact-only: no contact generation, allocation mutation, candidate
selection, import approval, Cadence write, or resource reservation.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `docs/artifacts/field_families/candidate_refresh_artifact.md`
- `lib/orbital_dynamics/candidate_refresh.ex`
- `lib/orbital_dynamics/communications/contact_intent.ex`
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/validation.ex`
- `schemas/candidate_refresh.v1.schema.json`
- `schemas/contact_intent_summary.v1.schema.json`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `study_results/validation_reference_fixtures.json`
- `test/orbital_dynamics/candidate_refresh_test.exs`
- `test/orbital_dynamics/communications/contact_intent_test.exs`
- `test/orbital_dynamics/schema_test.exs`
- `test/orbital_dynamics/validation_test.exs`

Tests run:
- `mix format lib/orbital_dynamics/candidate_refresh.ex lib/orbital_dynamics/communications/contact_intent.ex lib/orbital_dynamics/schema.ex test/orbital_dynamics/candidate_refresh_test.exs test/orbital_dynamics/communications/contact_intent_test.exs`
- `mix test test/orbital_dynamics/communications/contact_intent_test.exs`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs`
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix test test/orbital_dynamics/schema_test.exs test/orbital_dynamics/validation_test.exs`
- `mix orbital_dynamics.schema.lint --all`
- `git diff --check -- .codex/status/autonomous_product_loop.md docs/artifacts/field_families/candidate_refresh_artifact.md lib/orbital_dynamics/candidate_refresh.ex lib/orbital_dynamics/communications/contact_intent.ex lib/orbital_dynamics/schema.ex lib/orbital_dynamics/validation.ex schemas/candidate_refresh.v1.schema.json schemas/contact_intent_summary.v1.schema.json schemas/orbital_dynamics.schema_bundle.v1.json study_results/validation_reference_fixtures.json test/orbital_dynamics/candidate_refresh_test.exs test/orbital_dynamics/communications/contact_intent_test.exs test/orbital_dynamics/schema_test.exs test/orbital_dynamics/validation_test.exs`

Docs/artifacts changed:
CandidateRefresh docs now describe per-direction/per-ground-station contact
intent routing and station-scoped compact direction routing. Schema exports
were refreshed for the optional `contact_intent_summary.v1` and
`candidate_refresh.v1` fields, and the validation reference fixture report was
refreshed for the contact-intent direction replay fixture.

Last completed/pushed commit before this slice:
`d7df9bd` (`Replay list lifecycle provenance in candidate refresh`).

Next candidate:
Continue guide-backed resource/communications allocation work, likely
station-calendar or contact-allocation reservation/availability precedence, now
that contact-intent replay exposes station-scoped direction routing.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.

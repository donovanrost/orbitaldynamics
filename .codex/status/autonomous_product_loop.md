# Autonomous Product Loop Status

Current slice:
Resource-projection station-calendar provider ID replay.

Status:
Implemented with focused verification passing locally. CandidateRefresh
resource-projection source summaries and replay now preserve station-calendar
provider ID maps by pressure status and type next to the existing
station-calendar provider-entry maps. Storage/downlink pressure composition now
carries provider ID maps by pressure type and treats them as downlink pressure
evidence. ResourceProjection flow summaries now emit the same provider ID map by
pressure type, and the executable flow-summary schema validates it against
row-derived activity-resource-flow provider IDs.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `docs/artifacts/field_families/candidate_refresh_artifact.md`
- `lib/orbital_dynamics/candidate_refresh.ex`
- `lib/orbital_dynamics/resource_projection.ex`
- `lib/orbital_dynamics/schema.ex`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `schemas/resource_projection_flow_summary.v1.schema.json`
- `test/orbital_dynamics/candidate_refresh_test.exs`

Tests run:
- `mix format lib/orbital_dynamics/candidate_refresh.ex lib/orbital_dynamics/resource_projection.ex lib/orbital_dynamics/schema.ex test/orbital_dynamics/candidate_refresh_test.exs`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:9547 test/orbital_dynamics/candidate_refresh_test.exs:10313 test/orbital_dynamics/candidate_refresh_test.exs:11100 test/orbital_dynamics/candidate_refresh_test.exs:38345 test/orbital_dynamics/resource_projection_test.exs:3847 test/orbital_dynamics/resource_projection_test.exs:4001 test/orbital_dynamics/schema_test.exs:16680`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs`
- `mix test test/orbital_dynamics/resource_projection_test.exs`
- `mix test test/orbital_dynamics/schema_test.exs`
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix orbital_dynamics.schema.lint --all`
- `git diff --check`
- `git diff --cached --check`

Definition of done:
Raw resource-projection reports, flow summaries, artifact provenance, branch
candidate-source summaries, and storage/downlink composition preserve
station-calendar provider ID routing; provider-ID-only routing maps set the
expected pressure booleans; docs, schema exports, and focused tests are updated;
reviewer has no must-fix findings; the slice is committed and pushed without
staging `.gitignore`.

Last completed/pushed commit before this slice:
`f416252` (`Replay capacity pack direction pressure`).

Next candidate:
After this slice, continue guide-backed resource/communications allocation work
from queue item 2.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.

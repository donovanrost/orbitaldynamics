# Autonomous Product Loop Status

Current slice:
Timeline publication summary CandidateRefresh replay provenance.

Status:
Implemented, locally verified, reviewed clean, committed, and pushed.
`timeline_publication_summary.v1` can now be summarized through
CandidateRefresh branch-local replay provenance. The replay preserves direct
summaries, result-artifact wrapped summaries, and publication review/import
handoff rows without publishing, notifying, importing, mutating timelines,
selecting candidates, writing to Cadence, regenerating candidates, or granting
authority.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `docs/artifacts/field_families/candidate_refresh_artifact.md`
- `docs/artifacts/field_families/mission_activities.md`
- `docs/mission_planning/high_fidelity/04_plan_structure_and_lifecycle.md`
- `lib/orbital_dynamics.ex`
- `lib/orbital_dynamics/candidate_refresh.ex`
- `lib/orbital_dynamics/operator_review.ex`
- `lib/orbital_dynamics/schema.ex`
- `schemas/candidate_refresh.v1.schema.json`
- `schemas/orbital_dynamics.schema_bundle.v1.json`
- `test/orbital_dynamics/candidate_refresh_test.exs`
- `test/orbital_dynamics/schema_test.exs`

Definition of done:
- `CandidateRefresh.timeline_publication_replay_summary/1` emits
  artifact-only branch-local replay summaries.
- `OrbitalDynamics.candidate_refresh_timeline_publication_replay_summary/1`
  delegates to the CandidateRefresh helper.
- Capability metadata advertises `timeline_publication_summary` input,
  public facade, source-report helper, routing-map semantics, and branch replay
  semantics.
- Source-report provenance accepts direct
  `source_timeline_publication_summary` / `timeline_publication_summary`
  inputs, exact and wrapped `source_result_artifact` / `result_artifact`
  summaries, and publication rows preserved through operator-review packages
  and Cadence-import manifests.
- Replay preserves source paths/counts, publication IDs/status/authority,
  source artifact IDs/types, superseded/downstream/invalidated IDs,
  dependency-impact status/count/ID evidence, changed-field audit counts and
  routing, trust boundaries, and branch-local publication/dependency/
  changed-field/invalidation/review pressure booleans.
- Runtime validation and JSON Schema exports cover publication source-report
  provenance fields on `candidate_refresh.v1`.
- CandidateRefresh-derived activity-state handoff rows normalize
  `source_timeline_lifecycle_state` contract evidence without changing direct
  single-state operator-review rows.
- Docs, focused tests, full focused suites, schema export, schema export tests,
  schema lint, direct exported-schema check, and `git diff --check` pass.

Tests run:
- `mix format lib/orbital_dynamics.ex lib/orbital_dynamics/candidate_refresh.ex lib/orbital_dynamics/schema.ex`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:120` (passed after fixing one schema validation helper typo)
- `mix format lib/orbital_dynamics.ex lib/orbital_dynamics/candidate_refresh.ex lib/orbital_dynamics/schema.ex test/orbital_dynamics/candidate_refresh_test.exs`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:120 test/orbital_dynamics/candidate_refresh_test.exs:24792`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:24929 test/orbital_dynamics/candidate_refresh_test.exs:24948 test/orbital_dynamics/candidate_refresh_test.exs:25014` (failed once before adding the `import_action` Cadence-row alias, then passed focused)
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:25014`
- `mix test test/orbital_dynamics/schema_test.exs:11372`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:120 test/orbital_dynamics/candidate_refresh_test.exs:24793 test/orbital_dynamics/candidate_refresh_test.exs:24929 test/orbital_dynamics/candidate_refresh_test.exs:24948 test/orbital_dynamics/candidate_refresh_test.exs:25014 test/orbital_dynamics/schema_test.exs:11372`
- `MIX_OS_CONCURRENCY_LOCK=0 mix orbital_dynamics.schema.export --all --directory schemas --output schemas/orbital_dynamics.schema_bundle.v1.json`
- `mix test test/mix/tasks/orbital_dynamics.schema.export_test.exs`
- `mix orbital_dynamics.schema.lint --all`
- `mix test test/orbital_dynamics/schema_test.exs`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs` (failed once on an existing activity-state handoff assertion before narrowing CandidateRefresh-derived lifecycle-source normalization, then passed)
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:20668`
- `mix test test/orbital_dynamics/operator_review_test.exs` (failed once before limiting lifecycle-source normalization to `candidate_refresh.*` sources, then passed)
- `mix test test/orbital_dynamics/operator_review_test.exs:2781 test/orbital_dynamics/candidate_refresh_test.exs:20668`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs`
- `mix test test/orbital_dynamics/operator_review_test.exs`
- `mix test test/orbital_dynamics/cadence_import_test.exs`
- `mix test test/orbital_dynamics/schema_test.exs`
- `node - <<'NODE'` direct check confirming exported `candidate_refresh.v1`
  source-report schema exposes timeline publication provenance fields
- `git diff --check`
- `slice_reviewer`: no must-fix findings; noted only residual risk that
  publication handoff extraction selects the first matching review/import row,
  which matches the current one-row-per-summary producer shape

Last completed implementation commit:
`72e58b73fe2c1f2c990e3caac9cdd654cead937e` pushed to `origin/main`.

Last ledger correction commit:
`ac6b888` pushed to `origin/main`.

Next candidate:
Rerun the mapper against the current checkout.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.

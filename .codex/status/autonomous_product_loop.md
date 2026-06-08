# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Cadence-import resource-projection stale battery replay challenge coverage.

Status:
Implemented and parent-verified. Candidate-refresh replay tests now challenge
`CadenceImport.from_resource_projection_report/1` battery-margin replay against
stale base battery derivation inputs, proving the Cadence-import handoff path
preserves replayed battery state-of-charge, drops stale capacity/energy-derived
inputs, emits power-margin suppression, and validates the resulting
`candidate_refresh.v1` artifact. The full-file verification also exposed two
stale contact-allocation station-pressure fallback test fixtures; those tests
now delete newer status maps before exercising older ground-station/scalar
fallback paths.

Files changed:
- `test/orbital_dynamics/candidate_refresh_test.exs`
- `.codex/status/autonomous_product_loop.md`

Tests run:
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:51323`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:50233 test/orbital_dynamics/candidate_refresh_test.exs:51267 test/orbital_dynamics/candidate_refresh_test.exs:51323`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:7749 test/orbital_dynamics/candidate_refresh_test.exs:7784 test/orbital_dynamics/candidate_refresh_test.exs:51327`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs`
- `git diff --check`

Docs/artifacts changed:
- No public docs/artifacts changed; this is stale-input replay test hardening
  for an existing Cadence-import adapter path.

Level 6 pillar advanced:
Branch-local candidate refresh depth plus adapter-facing validation/challenge
coverage. Stale battery derivation inputs can no longer hide replayed
Cadence-import resource-projection power-margin pressure.

Remaining maturity gaps:
Compact adapter-facing handoffs still need more stale-observation coverage
across other source-report families where schema lint alone is weaker. Continue
reassessing Level 6 gaps from the guide after this Cadence-import challenge
slice is reviewed and published.

Last commit:
Pending for this slice. Previous pushed commit was
`ab913954ec7ea275746c383b85d3482f4a0da203`.

Next candidate:
After publishing this slice, reassess Level 6 gaps from the guide/ledger.
Likely next candidates remain another stale-observation challenge around
compact adapter handoffs or a small source-report replay hardening slice in a
different family.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Blocked:
No.

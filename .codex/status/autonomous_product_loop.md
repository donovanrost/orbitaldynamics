# Autonomous Product Loop Status

Current slice:
Storage/downlink capacity-pack direction replay.

Status:
Implemented with focused verification passing locally. CandidateRefresh
storage/downlink pressure replay now preserves contact-allocation capacity-pack
required, selected, and deferred demand maps by direction, plus all-contact,
selected, and deferred capacity-pack contact-ID maps by direction. Capacity-pack
pressure booleans now consider those direction maps, so a direction-scoped
downlink allocation handoff does not lose routing when composed with
link-capacity and resource-projection pressure.

Files changed:
- `.codex/status/autonomous_product_loop.md`
- `docs/artifacts/field_families/candidate_refresh_artifact.md`
- `lib/orbital_dynamics/candidate_refresh.ex`
- `test/orbital_dynamics/candidate_refresh_test.exs`

Tests run:
- `mix format lib/orbital_dynamics/candidate_refresh.ex test/orbital_dynamics/candidate_refresh_test.exs`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:10618`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:11049`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs`
- `git diff --check`

Definition of done:
Storage/downlink replay carries capacity-pack demand and contact-ID maps by
direction alongside existing station/status maps; pressure flags respond to
direction-only capacity-pack evidence; docs and tests cover the composed
boundary; focused and full CandidateRefresh verification pass; reviewer has no
must-fix findings; the slice is committed and pushed without staging
`.gitignore`.

Last completed/pushed commit before this slice:
`9783bbd` (`Replay allocation direction station routing`).

Next candidate:
After this slice, continue guide-backed resource/communications allocation work,
likely the next uncovered contact-allocation, station-calendar, or
storage/downlink replay boundary.

Blocked:
No.

Notes:
`.gitignore` still has an unrelated pre-existing local scratch-ignore change and
is not part of this slice. Treat current files as authoritative and do not
revert unrelated changes.

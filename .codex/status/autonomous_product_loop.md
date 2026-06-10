# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Timeline-publication handoff rows outrank stale embedded summaries.

Status:
Implemented, reviewer-cleared, locally verified, committed, and pushed.

Files changed:
- Timeline-publication handoff replay precedence:
  `lib/orbital_dynamics/candidate_refresh.ex`
- Focused replay regression:
  `test/orbital_dynamics/candidate_refresh_test.exs`
- Ledger:
  `.codex/status/autonomous_product_loop.md`

Tests/checks run:
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:27650 test/orbital_dynamics/candidate_refresh_test.exs:27859`
- `mix compile --warnings-as-errors`
- `git diff --check`

Level 6 pillar advanced:
Durable schema-versioned artifacts and reproducible branch-local replay
explanations for timeline-publication downstream invalidation pressure, by
making review/import handoff rows row-led when embedded publication summaries
are stale.

Slice selection note:
Selected slice: make timeline-publication handoff-row replay row-led when
embedded summaries are stale.

Why this slice: timeline-publication replay lifts summaries from
operator-review and Cadence-import handoff rows. Existing tests covered exact
embedded summaries and fallback after removing them, but not contradictory
embedded summaries. Handoff row fields should drive replay when present.

Current evidence gap closed:
Operator-review and Cadence-import handoff rows now carry deliberately stale
embedded `source_timeline_publication_summary` maps while their row fields
contain the live publication/downstream invalidation evidence. Replay summary
publication IDs, source artifact IDs, invalidated downstream products, row
counts, review timeline IDs, and pressure flags now prove row evidence wins.

Slice result:
- Changed timeline-publication handoff extraction to derive a summary from the
  handoff row first, falling back to embedded summaries only for sparse legacy
  rows.
- Extended the existing handoff-row replay test with stale embedded summaries
  for both operator-review packages and Cadence-import manifests.
- Added sparse legacy handoff coverage proving an embedded summary still wins
  when a row carries only identity-level publication fields.
- Neighboring timeline-publication replay tests remain green.

Last completed slice:
Timeline-publication handoff rows outrank stale embedded summaries.

Last pushed commits:
- Product/ledger: `5e11842` Preserve provider hold expiration pressure
- Ledger correction: `23ff2f6` Update autonomous loop ledger after provider
  hold publish
- Product/ledger: `0b4fdcd` Guard resource quality gate rows against stale
  aggregates
- Ledger correction: `c96eaa9` Update autonomous loop ledger after resource
  gate publish
- Product/ledger: `80f44b0` Prefer timeline publication handoff row evidence

Review/publish queue:
- Reviewer sidecar cleared the timeline-publication handoff stale embedded
  summary slice after sparse legacy fallback coverage was added.
- Published to `origin/main` as `80f44b0`.

Remaining maturity gaps:
- Continue converting replayed resource/contact/readiness pressure into
  planner-visible branch scoring or candidate-selection effects where live code
  still routes evidence only to review/import.
- Add exact challenge or compatibility fixtures for stale-but-plausible
  readiness/resource/contact inputs where current behavior is only protected by
  focused strategy assertions.
- Keep golden and validation-reference fixtures exact-regenerable whenever
  planner pressure families change public artifact shape.

Next candidate:
Reassess model acceptance, validation safety-case, or timeline lifecycle stale
aggregate strategy guards from live evidence.

Blocked:
Not blocked.

Notes:
- CandidateRefresh focused tests were quiet for this slice.
- Reviewer sidecar: `019eb04a-034b-76b3-b716-3c381de5a9b1`.
- Publisher sidecar: `019eb051-c3d5-76b0-b5d1-20cb6b417395`.

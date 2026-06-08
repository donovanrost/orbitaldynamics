# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Branch-local provider-reservation request effective-status replay.

Status:
Implemented and parent-verified. Candidate refresh now accepts
provider-reservation request summaries that carry full `rows` without separate
request/review row lists, rehydrates those full-row summaries through
`ContactAllocation.provider_reservation_request_summary/1`, and derives replay
counts, IDs, routing maps, and match-status reservation IDs from normalized
rows instead of stale top-level aggregates. Allocated rows whose effective
status is `policy_blocked` stay out of provider-request-ready routing, while
legacy allocated rows that omit `effective_allocation_status` still normalize
as request-ready when their reservation match is ready. Aggregate-only rowless
summaries from the same artifact model are still accepted through the explicit
top-level fallback path.

Files changed:
- `lib/orbital_dynamics/candidate_refresh.ex`
- `test/orbital_dynamics/candidate_refresh_test.exs`
- `.codex/status/autonomous_product_loop.md`

Tests run:
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:7236`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs:7370`
- `mix test test/orbital_dynamics/candidate_refresh_test.exs`
- `mix test test/orbital_dynamics/communications/contact_allocation_test.exs`
- `git diff --check`
- `mix test` (3226 passed; known `:propagator_exit` test log observed and suite exited green)

Docs/artifacts changed:
- No public docs or schema exports changed; this tightens candidate-refresh
  replay semantics for the existing
  `contact_allocation_provider_reservation_request_summary.v1` artifact family.

Level 6 pillar advanced:
Fleet-level resource/contact/station-calendar allocation behavior plus
approval-aware provider-boundary routing in branch-local refresh replay.
Candidate-refresh source-report provenance now preserves the direct
contact-allocation effective-status boundary instead of reintroducing
policy-blocked provider requests from stale replay aggregates.

Remaining maturity gaps:
Resource/contact allocation still needs deeper planner-visible behavior for
provider-calendar capacity and reservation pressure during candidate selection.
Typed timeline lifecycle/publication semantics still need additional Level 6
hardening.

Last commit:
`54fd7ed` Replay provider reservation requests from rows.

Next candidate:
Reassess Level 6 gaps from the guide/ledger. Likely candidates include
planner-visible reduced-capacity/contact-allocation behavior in branch-local
candidate refresh, or another typed timeline lifecycle/publication hardening
slice.

Unrelated local changes:
- `.gitignore` has an unrelated pre-existing local scratch-ignore change and is
  not part of this slice.

Previous published slice:
- `e74d003` honored effective status in provider-reservation request summaries.
- `5b7f273` updated the quality-gate resource handoff.
- `003073f` validated quality-gate resource handoff evidence.
- `f9c215e` updated the transition evidence handoff.
- `6f3b981` validated transition selected activity evidence.

Blocked:
No.

Notes:
- Read-only reviewer found no issue with the full-row policy-blocked behavior
  and flagged a missing aggregate-only rowless fallback regression. The final
  slice includes that detection/test follow-up.

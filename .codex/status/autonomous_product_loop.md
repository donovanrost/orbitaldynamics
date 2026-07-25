# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Preserve V2 source compact link-capacity summary handoff.

Status:
Verified; publication pending.

Selection evidence:
- CandidateRefresh accepts the separately versioned `link_capacity_summary.v1`
  from direct, canonical, nested, result-artifact, and list-valued source paths.
  It preserves row-derived contact/station identities, selected and actual
  throughput, required downlink, shortfall, capacity-adjusted throughput,
  reservation, station-calendar provider, trust, and provenance routes.
- The compact summary can arrive without the full link-capacity report. Its
  assumptions declare artifact-only behavior, no provider reservation, no
  schedule mutation, and no operator authority.
- Existing operator-review/Cadence conversion synthesizes a review-gated row
  per station from compact summary aggregates. Campaign repair V2 currently
  preserves only the full report, so the compact compatibility boundary is
  otherwise lost.

Intended behavior:
- Resolve source/canonical/list-valued compact link-capacity summaries and
  preserve the first map exactly at `source_link_capacity_summary` on repair
  V2.
- Validate the optional field against its full executable contract at the
  distinct source path and export the versioned property.
- Reuse existing summary-to-review conversion so station/contact identity,
  throughput, shortfall, reservation, and provider-entry evidence reaches
  operator review and review-gated Cadence handoff with exact provenance.
- Keep the compact summary out of repair scoring, candidate selection,
  schedules, provider/Cadence writes, operator authority, and autonomous
  execution.

Level 6 pillar advanced:
Fleet-scale planning decisions and durable reproducible audit handoffs.

Delivered behavior:
- V2 resolves direct, canonical, nested, result-artifact, and list-valued
  compact link-capacity summaries, selecting the first map and preserving it
  exactly at `source_link_capacity_summary`.
- The optional source field receives its own full path-aware executable
  validation, registry contract, type hint, and exported schema property.
- Existing compact-summary conversion now supplies exact review-gated
  station rows to the composite operator-review and Cadence artifacts,
  including selected/actual contact IDs, throughput, required downlink,
  shortfall, reservation, provider-entry, trust, and source context.
- The source summary remains distinct from the generated repair report and
  does not affect scoring, candidate selection, schedules, effects, provider
  or Cadence writes, operator authority, or autonomous execution.

Verification:
- Focused source/schema/integration proof: `21 passed`.
- Adjacent compact-summary proof: `29 passed`.
- Link-capacity family: `100 passed`.
- Contact-allocation family: `238 passed`.
- Golden-artifact suite: `12 passed`.
- Full schema lint: `155 artifacts`, zero errors and zero warnings.
- Pre-export full suite: `5028/5029 passed`; sole failure was the expected
  generated-schema export mismatch (`638.1s`).
- Regenerated schema exports changed exactly `campaign_repair.v2.schema.json`
  and `orbital_dynamics.schema_bundle.v1.json`; manifest and canonical repair
  and strategy outputs stayed byte-identical.
- Repair schema SHA-256:
  `1dabb7ee95353f61e8fc6430c51353c80b20118e049039141105cb8256c15b30`.
- Bundle SHA-256:
  `74e675d7c05b52f728c2a4bcea22915845dc6ca4828e8fd1b40d678aee255868`.
- Schema export proof: `3 passed` (`55.9s`).
- Final full suite: `5029 passed` (`654.4s`).
- `mix format --check-formatted` and `git diff --check` pass.

Review:
- Exact integration assertions cover preserved source payloads, the synthesized
  operator-review row, and review-gated Cadence projection with
  `has_cadence_import: false`.
- The newly reusable summary converter remains an internal, undocumented
  operator-review helper and is exercised by both the compact-summary and
  broader link-capacity families.
- No repair pressure, scoring, selection, scheduling, or effect code reads the
  new source field. Stable canonical output hashes and the full suite confirm
  no planning regression.

Last published slice:
- `8455818e` Preserve V2 compact contention resolution (`5024 passed`; two
  exact review-only group rows, no candidate selection, provider reservation,
  schedule mutation, Cadence write, operator authority, or execution).

Remaining maturity gaps:
- Continue fleet-scale station/allocation decisions while preserving explicit
  provider and Cadence execution boundaries.
- Add planner effects only for allocation/resource evidence with selected
  candidate identity; keep compact aggregate maps provenance-only.
- Continue broader schema/versioned compatibility discipline and stale-input
  challenge fixtures.

Next candidate:
After publication, audit the next bounded CandidateRefresh source-report gap
by product value and distinctness.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent performs bounded
mapping, implementation, review, verification, and publish checks.

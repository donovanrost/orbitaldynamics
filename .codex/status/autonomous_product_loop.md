# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Preserve V2 source relay data-path summary handoff.

Status:
Verified; publication pending.

Selection evidence:
- CandidateRefresh accepts the separately versioned
  `relay_data_path_summary.v1` from direct, canonical, accepted-planning-state,
  mission-state, result-artifact, and list-valued source paths. It derives
  route-level source/relay spacecraft, downlink contact, ground-station,
  custody, latency, and risk evidence from exact rows.
- The compact relay summary can arrive independently from the link-capacity
  report. Its assumptions explicitly declare artifact-only behavior, no relay
  scheduling, no custody acknowledgement delivery, no provider reservation,
  no schedule mutation, and no operator authority.
- Existing operator-review/Cadence conversion already produces review-gated
  route rows from this summary. Campaign repair V2 has no distinct source field,
  so this operational evidence is currently lost at the repair handoff.

Intended behavior:
- Resolve source/canonical/list-valued relay data-path summaries and preserve
  the first map exactly at `source_relay_data_path_summary` on repair V2.
- Validate the optional field against its full executable contract at the
  distinct source path and export the versioned property.
- Reuse existing relay-summary conversion so exact route, spacecraft chain,
  downlink contact, station, custody, latency, and risk evidence reaches
  operator review and review-gated Cadence handoff with source provenance.
- Keep the summary out of repair scoring, candidate selection, relay
  scheduling, provider/Cadence writes, operator authority, and autonomous
  execution.

Level 6 pillar advanced:
Fleet-scale planning decisions and durable reproducible audit handoffs.

Delivered behavior:
- V2 resolves source, canonical, and list-valued relay data-path summaries,
  selecting the first map and preserving it exactly at
  `source_relay_data_path_summary`.
- The optional source field receives its own full path-aware executable
  validation, registry contract, type hint, and exported schema property.
- Existing relay-summary conversion now supplies exact review-gated route rows
  to the composite operator-review and Cadence artifacts, including route,
  source/relay spacecraft, ground contact/station, custody, latency, risk,
  assumptions, and source context.
- The source summary remains distinct from generated link-capacity evidence and
  does not affect scoring, candidate selection, relay scheduling, schedules,
  effects, provider or Cadence writes, operator authority, or autonomous
  execution.

Verification:
- Focused source/schema/replay/review/integration proof: `27 passed`.
- Adjacent relay/link-capacity family: `105 passed`.
- Contact-allocation family: `238 passed`.
- Golden-artifact suite: `12 passed`.
- Full schema lint: `155 artifacts`, zero errors and zero warnings.
- Pre-export full suite: `5033/5034 passed`; sole failure was the expected
  generated-schema export mismatch (`660.1s`).
- Regenerated schema exports changed exactly `campaign_repair.v2.schema.json`
  and `orbital_dynamics.schema_bundle.v1.json`; manifest and canonical repair
  and strategy outputs stayed byte-identical.
- Repair schema SHA-256:
  `928328af1eae41d5d06e5cd2334b10ed036b0de280d72b5a836e362bb1403629`.
- Bundle SHA-256:
  `3d31bc7d83a638167d60ae93bb5f994a732ba93a73ed5cd24c7b6581aa1f0627`.
- Schema export proof: `3 passed` (`51.2s`).
- Final full suite: `5034 passed` (`636.3s`).
- `mix format --check-formatted` and `git diff --check` pass.

Review:
- Exact integration assertions cover the preserved source payload, nominal
  relay route in operator review, high-risk direct route in review-gated
  Cadence projection, and `has_cadence_import: false`.
- The existing relay converter preserves row-level evidence and compact source
  context; its broader relay/link-capacity family remains green.
- Only resolution, artifact assembly, validation/export, and review projection
  read the new V2 source field. Stable canonical hashes and the full suite
  confirm no scoring, selection, scheduling, or execution regression.

Last published slice:
- `9b544270` Preserve V2 source compact link capacity (`5029 passed`; exact
  compact evidence reaches review and Cadence handoff without entering repair
  scoring, selection, schedules, writes, authority, or execution).

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

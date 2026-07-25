# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Preserve V2 source realized-state snapshot handoff.

Status:
Verified; publish pending.

Selection evidence:
- CandidateRefresh accepts `realized_state_snapshot.v1` containers from
  direct/canonical, accepted-planning-state, mission-state, result-artifact,
  and list-valued source paths when deriving realized operational feedback.
- One snapshot is a versioned aggregate that retains exact realized activities,
  spacecraft states, provider/trust-boundary metadata, row-derived counts,
  assumptions, and model limits.
- Repair V2 has its own current `realized_state_snapshot` from the repair
  request but does not preserve the distinct upstream CandidateRefresh
  snapshot, so accepted operational provenance is discarded at handoff.
- Existing realized-state review conversion maps snapshot activities into
  typed realized-feedback rows. It grants no schedule mutation, import
  approval, command authority, or execution authority.

Intended behavior:
- Resolve source/canonical/list-valued realized-state snapshots and preserve the
  first accepted aggregate map exactly at `source_realized_state_snapshot` on
  repair V2, independently from the request's current snapshot.
- Validate the optional field against its full executable contract at the
  distinct source path and export the versioned property.
- Extend the existing realized-state conversion with a source-aware row API so
  realized activities and exact snapshot context reach review-gated Cadence
  handoff.
- Keep the source snapshot out of repair scoring, candidate selection, current
  realized-state derivation, schedule/timeline mutation, publication,
  provider/Cadence writes, import approval/operator authority, commanding, and
  autonomous execution.

Level 6 pillar advanced:
Fleet-scale resource decisions and durable reproducible audit handoffs.

Planned files:
- V2 CandidateRefresh realized-state-snapshot resolution and artifact assembly
- source-aware realized-state review conversion
- V2 path-aware validation, registry/type hints, and review/Cadence routing
- focused source/schema/integration proofs, docs, exports, and ledger

Verification:
- Focused resolver/schema/adapter proofs: `8 passed` in 8.9s.
- Focused repair handoff proof: `11 passed` in 11.4s.
- Realized-state and operational-feedback regression family: `85 passed` in
  11.6s.
- Contact-allocation regression suite: `238 passed` in 16.3s.
- Golden artifacts: `12 passed` in 20.7s.
- Schema lint: 155 artifacts, 0 errors, 0 warnings.
- Pre-export full suite: expected checked-in-schema mismatch only,
  `5109/5110 passed` in 695.4s.
- Regenerated repair schema and bundle only; repair, strategy, and manifest
  canonical hashes remained stable.
- Schema-export proof: `3 passed` in 50.9s.
- Final full suite: `5110 passed` in 688.0s.

Review:
The exact upstream snapshot stays on repair V2 while each source activity is
converted through the existing realized-feedback semantics and retains the
snapshot's complete activity, spacecraft-state, metadata, trust-boundary,
count, and model-limit context through review-gated Cadence handoff. The source
snapshot remains distinct from the repair request's operative
`realized_state_snapshot` and does not affect current-state derivation, repair
scoring or candidate selection, mutate or publish a schedule, write to Cadence,
grant import/operator authority, command, or execute work. Generated drift is
limited to `campaign_repair.v2.schema.json` and the bundle.

Last published slice:
- `1e32cbea` Preserve V2 source transition application summary (`5104 passed`;
  exact aggregate transition review evidence reaches review and Cadence
  handoff without applying transitions, mutating schedules, granting authority,
  or executing work).

Remaining maturity gaps:
- Continue fleet-scale station/allocation decisions while preserving explicit
  provider and Cadence execution boundaries.
- Add planner effects only for allocation/resource evidence with selected
  candidate identity; keep compact aggregate maps provenance-only.
- Preserve per-activity precondition collections only after choosing an
  explicitly lossless plural V2 shape rather than a first-map coercion.
- Continue broader schema/versioned compatibility discipline and stale-input
  challenge fixtures.

Next candidate:
After source realized-state-snapshot evidence is durable, audit the next
bounded CandidateRefresh aggregate source-report gap by product value and
distinctness.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent performs bounded
mapping, implementation, review, verification, and publish checks.

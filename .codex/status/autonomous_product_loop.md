# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Preserve V2 source contact-intent summary handoff.

Status:
Verified; publish pending.

Selection evidence:
- CandidateRefresh accepts `contact_intent_summary.v1` from direct/canonical,
  accepted-planning-state, mission-state, result-artifact, and list-valued
  paths.
- One summary aggregates the accepted contact-intent set and retains exact
  direction/station routing, contact identities, capacity-pack membership,
  required capacity fractions, source model, provenance, and boundary
  assumptions.
- Repair V2 preserves materialized `source_contact_intents` but not an accepted
  compact summary, so summary-only CandidateRefresh inputs lose exact aggregate
  capacity-demand evidence before repair operator-review and Cadence handoff.
- Existing contact-intent review/Cadence conversion already synthesizes one
  review row per direction with station and required-capacity context. The
  summary explicitly grants no provider reservation or schedule mutation.

Intended behavior:
- Resolve source/canonical/list-valued contact-intent summaries and preserve the
  first aggregate map exactly at `source_contact_intent_summary` on repair V2.
- Validate the optional field against its full executable contract at the
  distinct source path and export the versioned property.
- Reuse existing contact-intent-summary conversion so exact direction/station
  routing, contact identities, capacity-pack membership, required fractions,
  provenance, and boundary context reach review and review-gated Cadence
  handoff.
- Keep the source summary out of station allocation/reservation, repair scoring,
  candidate selection, schedule/timeline mutation, publication, provider/Cadence
  writes, approval/operator authority, commanding, and autonomous execution.

Level 6 pillar advanced:
Fleet-scale resource decisions and durable reproducible audit handoffs.

Planned files:
- V2 CandidateRefresh contact-intent-summary resolution and artifact assembly
- V2 path-aware validation, registry/type hints, and review/Cadence routing
- focused source/schema/integration proofs, docs, exports, and ledger

Verification:
- Focused resolver/schema proofs: `5 passed` in 8.8s.
- Focused repair handoff proof: `11 passed` in 10.6s.
- Contact-intent regression family: `77 passed` in 9.9s.
- Contact-allocation regression suite: `238 passed` in 16.0s.
- Golden artifacts: `12 passed` in 36.1s.
- Schema lint: 155 artifacts, 0 errors, 0 warnings.
- Pre-export full suite: expected checked-in-schema mismatch only,
  `5093/5094 passed` in 661.1s.
- Regenerated repair schema and bundle only; repair, strategy, and manifest
  canonical hashes remained stable.
- Schema-export proof: `3 passed` in 51.5s.
- Final full suite: `5094 passed` in 655.4s.

Review:
The exact upstream aggregate stays on repair V2 while direction-scoped review
rows retain station/contact identity, capacity-pack membership, required
capacity fractions, source model, provenance, and the compact aggregate through
review-gated Cadence handoff. The optional field is separately validated and
does not allocate or reserve provider capacity, change repair scoring or
candidate selection, mutate or publish the schedule, write to Cadence, grant
authority, command, or execute work. Generated drift is limited to
`campaign_repair.v2.schema.json` and the bundle.

Last published slice:
- `1a8922a5` Preserve V2 source resource filter summary (`5089 passed`; exact
  aggregate suppression evidence reaches review and Cadence handoff without
  filtering candidates, changing repair scoring, granting authority, or
  executing work).

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
After source contact-intent-summary evidence is durable, audit the next
bounded CandidateRefresh aggregate source-report gap by product value and
distinctness.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent performs bounded
mapping, implementation, review, verification, and publish checks.

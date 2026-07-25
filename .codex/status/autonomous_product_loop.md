# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Preserve V2 source timeline-diff summary handoff.

Status:
Verified; publish pending.

Selection evidence:
- CandidateRefresh accepts `timeline_diff_summary.v1` from direct/canonical,
  accepted-planning-state, mission-state, result-artifact, review-artifact,
  Cadence-manifest, and list-valued paths.
- A timeline-diff summary is an aggregate comparison contract whose embedded
  review rows retain added, removed, changed, protected, status/approval
  transition, duplicate-identity, invalid-input, and operator-action evidence.
- Repair V2 preserves the larger timeline-diff report but not an accepted
  source summary, so summary-only CandidateRefresh inputs lose their exact
  evidence before repair operator-review and Cadence handoff.
- Existing CandidateRefresh operator-review/Cadence conversion already routes
  summary review rows. The summary explicitly declares no timeline mutation,
  transition application, Cadence import, commanding, or operator authority.
- The preceding activity-precondition candidate was rejected because its
  singular source key is naturally collection-valued across distinct
  activities; preserving only the first map would silently discard evidence.

Intended behavior:
- Resolve source/canonical/list-valued timeline-diff summaries and preserve the
  first aggregate map exactly at `source_timeline_diff_summary` on repair V2.
- Validate the optional field against its full executable contract at the
  distinct source path and export the versioned property.
- Reuse existing timeline-diff summary conversion so exact change counts,
  timeline identities, transitions, protected context, duplicate/invalid
  evidence, reasons, and operator actions reach review and review-gated Cadence
  handoff.
- Keep the source summary out of repair scoring, candidate selection, timeline
  mutation or transition application, publication, provider/Cadence writes,
  approval/operator authority, commanding, and autonomous execution.

Level 6 pillar advanced:
Fleet-scale planning decisions and durable reproducible audit handoffs.

Planned files:
- V2 CandidateRefresh timeline-diff-summary resolution and artifact assembly
- V2 path-aware validation, registry/type hints, and review/Cadence routing
- focused source/schema/integration proofs, docs, exports, and ledger

Verification:
- Focused resolver/schema proofs: `7 passed` in 8.9s.
- Focused repair/timeline-diff/Cadence proofs: `21 passed` in 9.4s.
- Timeline-adjacent regression suite: `632 passed` in 31.6s.
- Contact-allocation regression suite: `238 passed` in 19.6s.
- Golden artifacts: `12 passed` in 27.0s.
- Schema lint: 155 artifacts, 0 errors, 0 warnings.
- Pre-export full suite: expected checked-in-schema mismatch only,
  `5078/5079 passed` in 682.0s.
- Regenerated repair schema and bundle only; repair, strategy, and manifest
  canonical hashes remained stable.
- Export plus focused proof: `21 passed` in 52.5s.
- Final full suite: `5079 passed` in 661.4s.

Review:
Exact upstream source/replacement identity, added/removed/changed counts,
protected status/approval transitions, changed fields, duplicate/invalid input
evidence, reasons, and operator actions reach review and review-gated Cadence
rows. The optional field is separately validated and does not affect repair
scoring, candidate selection, transition application, timeline mutation,
publication, provider/Cadence writes, authority, commanding, or execution.
Generated drift is limited to `campaign_repair.v2.schema.json` and the bundle.

Last published slice:
- `1ef0b0c1` Preserve V2 source lifecycle state (`5074 passed`; exact incoming
  planned/realized identity, lifecycle and approval transitions, protection,
  and duplicate-identity evidence reaches review and Cadence handoff without
  changing timeline state, authority, or execution).

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
After source timeline-diff-summary evidence is durable, audit the next bounded
CandidateRefresh aggregate source-report gap by product value and distinctness.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent performs bounded
mapping, implementation, review, verification, and publish checks.

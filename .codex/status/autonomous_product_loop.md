# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Preserve CandidateRefresh source-window lineage in repair V2.

Status:
Implemented, reviewed, and verified; ready for scoped publication.

Selection evidence:
- Every generated CandidateRefresh artifact carries a stable ordered
  `source_window_lineage` collection linking candidate activity IDs to exact
  source-window IDs, types, source-window payloads, and scoped planning context.
- Repair V2 already retains candidate activities and the candidate-diff report,
  but drops the top-level lineage collection.
- The existing candidate-diff review adapter accepts lineage context. Without
  it, repair review and Cadence rows cannot attach exact invalidated or
  replacement source-window evidence even when CandidateRefresh supplied it.
- This is provenance-only evidence: it can improve operator inspection without
  changing candidate matching, repair ranking, selection, or schedule state.

Intended behavior:
- Preserve every CandidateRefresh `source_window_lineage.v1` map in its existing
  stable order at repair V2's `source_window_lineage` field, without
  deduplication or reconstruction.
- Validate every array element against the embedded lineage contract at its
  exact indexed path, reject any declared version drift while retaining legacy
  accepted rows without an explicit contract tag, and export the nested
  contract definition.
- Pass the preserved collection only to the existing candidate-diff review
  conversion so invalidated and replacement review/Cadence rows carry the exact
  matching lineage and source-window payload.
- Keep lineage out of candidate matching, repair scoring/ranking/selection,
  schedule or timeline mutation, provider/Cadence writes, approval/operator
  authority, commanding, and autonomous execution.

Level 6 pillar advanced:
Fleet-scale resource decisions and durable reproducible audit handoffs.

Planned files:
- lossless CandidateRefresh lineage resolution and repair artifact assembly
- indexed validation, registry metadata, and existing candidate-diff
  review/Cadence routing
- focused source/schema/integration proofs, docs, exports, and ledger

Verification:
- Focused resolver, schema, and end-to-end repair proofs: `16 passed` in 20.0s.
- Adjacent candidate-diff and CandidateRefresh contract family: `49 passed` in
  2.1s, including legacy lineage rows without explicit contract tags.
- Contact-allocation regression family: `238 passed` in 18.2s.
- Schema lint: `155` artifacts passed with `0` errors and `0` warnings.
- Pre-export full suite: `5138/5140 passed` in 701.8s; the two expected failures
  were the checked-in repair schema export and canonical strategy snapshot.
- A temporary canonical comparison found exactly `256` changed leaves: lineage
  additions under branch repair results and candidate-diff review/Cadence rows,
  plus the five content-derived strategy/review/manifest identifiers. No score,
  rank, decision, count, or schedule value changed.
- Regenerated all schema exports, the manifest schema, and both canonical
  campaigns. Changed generated files are limited to the repair schema, schema
  bundle, and canonical strategy artifact.
- Canonical repair and manifest hashes remained
  `867928e8aa95ba8473fffe017e7d1efda9d9e83799516a2a938ef7bb8c25f7fa`
  and `7a44a6e58754aae967ee8319c8768b7270d7d7982667c4a6bad8ff1c274c0594`.
  The deterministic strategy hash is now
  `db375d99bfb50a1a189ceed4ed206d88f8036347bd42d2772bc2d8426489fa60`
  with content-derived strategy ID
  `5f902662c10e34697c88a438b700eaadb9bd392823ceff83abe315eee0035aac`.
- Checked-in schema export gate: `3 passed` in 59.4s.
- Golden artifact gate: `12 passed` in 44.4s.
- Final full suite: `5140 passed` in 755.5s.
- `git diff --check` passed.

Review:
- Scope is additive: one optional repair collection, indexed embedded-contract
  validation, registry/schema metadata, and a lineage argument to the existing
  candidate-diff review conversion.
- Resolution retains source map order and contents, stringifies keys, and does
  not deduplicate or reconstruct lineage rows.
- Generated CandidateRefresh rows retain their explicit
  `source_window_lineage.v1` tag. Legacy accepted rows without a tag remain
  compatible; any explicitly declared wrong tag is rejected at its exact index.
- Candidate-diff review and Cadence rows gain only matching source/replacement
  lineage, source-window payload, and type context. The collection is not read
  by repair execution, matching, scoring, ranking, or selection.
- Canonical strategy identity changed because repair-result content is hashed.
  The curated golden assertion now pins the new deterministic ID, while all
  branch scores, recommendation decisions, review/import counts, and schedule
  surfaces remain unchanged.
- The slice does not mutate a schedule or timeline, write Cadence/provider
  state, reserve contacts, command activity, grant approval/operator authority,
  or execute autonomously.

Last published slice:
- `659903a0` Preserve plural V2 publication summaries (`5135 passed`; distinct
  publication events are retained in stable source-before-canonical order and
  remain review-only without accepting publication authority).

Remaining maturity gaps:
- Continue fleet-scale station/allocation decisions while preserving explicit
  provider and Cadence execution boundaries.
- Add planner effects only for allocation/resource evidence with selected
  candidate identity; keep compact aggregate maps provenance-only.
- Preserve remaining source collections only with explicitly lossless plural
  V2 shapes rather than first-map coercion.
- Continue broader schema/versioned compatibility discipline and stale-input
  challenge fixtures.

Next candidate:
After source-window lineage is durable, audit the next bounded CandidateRefresh
source collection by product value and distinctness.

Blocked:
None.

Notes:
Runtime policy disallows subagent delegation; the parent performs bounded
mapping, implementation, review, verification, and publish checks.
